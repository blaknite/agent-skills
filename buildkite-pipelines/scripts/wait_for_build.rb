#!/usr/bin/env ruby
# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

def load_credentials
  require "yaml"
  path = File.expand_path("~/.config/buildkite/credentials.yml")
  return unless File.exist?(path)

  creds = YAML.load_file(path)
  ENV["BUILDKITE_API_TOKEN"] ||= creds["buildkite_api_token"].to_s
  ENV["LINEAR_API_KEY"] ||= creds["linear_api_key"].to_s
end

load_credentials

BASE_URL = "https://api.buildkite.com/v2"
POLL_INTERVAL = 10

def api_token
  token = ENV["BUILDKITE_API_TOKEN"]
  unless token
    warn "Error: BUILDKITE_API_TOKEN environment variable is not set"
    exit 1
  end
  token
end

def api_get(path)
  uri = URI("#{BASE_URL}#{path}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Get.new(uri)
  request["Authorization"] = "Bearer #{api_token}"

  response = http.request(request)

  case response.code.to_i
  when 200
    JSON.parse(response.body)
  when 401
    warn "Error: Unauthorized. Check your BUILDKITE_API_TOKEN."
    exit 1
  when 404
    nil
  else
    warn "Error: API returned #{response.code}: #{response.body}"
    exit 1
  end
end

def get_build(org, pipeline, branch: nil)
  query = "per_page=1"
  query += "&branch=#{URI.encode_www_form_component(branch)}" if branch
  builds = api_get("/organizations/#{org}/pipelines/#{pipeline}/builds?#{query}")
  builds&.first
end

def terminal_state?(state)
  %w[passed failed canceled].include?(state)
end

def has_failures?(build)
  jobs = build["jobs"] || []
  jobs.any? { |j| %w[failed timed_out].include?(j["state"]) }
end

def job_summary(build)
  jobs = build["jobs"] || []
  states = jobs.group_by { |j| j["state"] }.transform_values(&:count)
  states.map { |state, count| "#{count} #{state}" }.join(", ")
end

def parse_args(args)
  options = { org: nil, pipeline: nil, branch: nil, timeout: 3600 }
  positional = []

  i = 0
  while i < args.length
    case args[i]
    when "--branch", "-b"
      options[:branch] = args[i + 1]
      i += 2
    when "--timeout", "-t"
      options[:timeout] = args[i + 1].to_i
      i += 2
    else
      positional << args[i]
      i += 1
    end
  end

  if positional[0]&.include?("/")
    options[:org], options[:pipeline] = positional[0].split("/", 2)
  else
    options[:org] = positional[0]
    options[:pipeline] = positional[1]
  end
  options
end

options = parse_args(ARGV)

if options[:org].nil? || options[:pipeline].nil?
  warn "Usage: #{$PROGRAM_NAME} <org/pipeline> [--branch BRANCH] [--timeout SECONDS]"
  warn ""
  warn "Waits for a build to exist and reach a terminal state (passed/failed/canceled)"
  warn "or start failing (has failed jobs)."
  warn ""
  warn "Options:"
  warn "  --branch, -b   Wait for build on specific branch"
  warn "  --timeout, -t  Maximum wait time in seconds (default: 3600)"
  warn ""
  warn "Examples:"
  warn "  #{$PROGRAM_NAME} buildkite/buildkite --branch my-feature"
  warn "  #{$PROGRAM_NAME} buildkite/buildkite --branch main --timeout 1800"
  exit 1
end

org = options[:org]
pipeline = options[:pipeline]
branch = options[:branch]
timeout = options[:timeout]
start_time = Time.now
last_build_number = nil

puts "Waiting for build on #{org}/#{pipeline}#{branch ? " (branch: #{branch})" : ""}..."

loop do
  elapsed = Time.now - start_time
  if elapsed > timeout
    warn "Timeout: No terminal state reached after #{timeout} seconds"
    exit 1
  end

  build = get_build(org, pipeline, branch: branch)

  if build.nil?
    print "\rWaiting for build to exist... (#{elapsed.to_i}s elapsed)"
    sleep POLL_INTERVAL
    next
  end

  build_number = build["number"]
  state = build["state"]

  if build_number != last_build_number
    last_build_number = build_number
    puts "\nFound build ##{build_number}: #{state}"
    puts "URL: #{build['web_url']}"
  end

  if terminal_state?(state) || has_failures?(build)
    puts "\n"
    puts "Build ##{build_number}: #{state.upcase}"
    puts "Branch: #{build['branch']}"
    puts "Message: #{build['message']&.lines&.first&.strip}"
    puts "Author: #{build.dig('creator', 'name') || build.dig('author', 'name') || 'Unknown'}"
    puts "URL: #{build['web_url']}"
    puts "Jobs: #{job_summary(build)}"
    exit(state == "passed" ? 0 : 1)
  end

  print "\rBuild ##{build_number}: #{state} - #{job_summary(build)} (#{elapsed.to_i}s elapsed)    "
  $stdout.flush
  sleep POLL_INTERVAL
end
