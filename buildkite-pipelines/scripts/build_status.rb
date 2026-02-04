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
    warn "Error: Not found. Check org, pipeline, and build number."
    exit 1
  else
    warn "Error: API returned #{response.code}: #{response.body}"
    exit 1
  end
end

def get_build(org, pipeline, number: nil, branch: nil)
  if number
    api_get("/organizations/#{org}/pipelines/#{pipeline}/builds/#{number}")
  else
    query = "per_page=1"
    query += "&branch=#{URI.encode_www_form_component(branch)}" if branch
    builds = api_get("/organizations/#{org}/pipelines/#{pipeline}/builds?#{query}")
    if builds.empty?
      warn "Error: No builds found for #{org}/#{pipeline}#{branch ? " on branch #{branch}" : ""}"
      exit 1
    end
    builds.first
  end
end

def job_state_emoji(state)
  case state
  when "passed" then "✓"
  when "failed" then "✗"
  when "running" then "▶"
  when "scheduled" then "○"
  when "waiting" then "…"
  when "blocked" then "■"
  when "canceled" then "⊘"
  when "timed_out" then "⏱"
  else "?"
  end
end

def format_build(build)
  output = []
  output << "Build ##{build['number']}: #{build['state'].upcase}"
  output << "Branch: #{build['branch']}"
  output << "Message: #{build['message']&.lines&.first&.strip}"
  output << "Author: #{build.dig('creator', 'name') || build.dig('author', 'name') || 'Unknown'}"
  output << "URL: #{build['web_url']}"

  jobs = build["jobs"] || []
  job_states = jobs.group_by { |j| j["state"] }.transform_values(&:count)
  summary = job_states.map { |state, count| "#{count} #{state}" }.join(", ")
  output << "Jobs: #{summary}"

  output.join("\n")
end

def parse_args(args)
  options = { org: nil, pipeline: nil, number: nil, branch: nil }
  positional = []

  i = 0
  while i < args.length
    case args[i]
    when "--branch", "-b"
      options[:branch] = args[i + 1]
      i += 2
    else
      positional << args[i]
      i += 1
    end
  end

  # Support "org/pipeline" format
  if positional[0]&.include?("/")
    options[:org], options[:pipeline] = positional[0].split("/", 2)
    options[:number] = positional[1]
  else
    options[:org] = positional[0]
    options[:pipeline] = positional[1]
    options[:number] = positional[2]
  end
  options
end

options = parse_args(ARGV)

if options[:org].nil? || options[:pipeline].nil?
  warn "Usage: #{$PROGRAM_NAME} <org/pipeline> [build_number] [--branch BRANCH]"
  warn ""
  warn "Examples:"
  warn "  #{$PROGRAM_NAME} buildkite/buildkite                      # Latest build"
  warn "  #{$PROGRAM_NAME} buildkite/buildkite 12345                # Specific build"
  warn "  #{$PROGRAM_NAME} buildkite/buildkite --branch my-feature  # Latest on branch"
  exit 1
end

build = get_build(options[:org], options[:pipeline], number: options[:number], branch: options[:branch])
puts format_build(build)
