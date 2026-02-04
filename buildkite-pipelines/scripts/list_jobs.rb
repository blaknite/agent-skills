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
FAILURE_STATES = %w[failed timed_out].freeze

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

def get_build(org, pipeline, number)
  api_get("/organizations/#{org}/pipelines/#{pipeline}/builds/#{number}")
end

def format_jobs(build, states:)
  jobs = build["jobs"] || []

  # Filter by state if specified
  if states && !states.empty?
    if states == ["failed"]
      # Special case: "failed" includes timed_out
      jobs = jobs.select { |j| FAILURE_STATES.include?(j["state"]) }
    else
      jobs = jobs.select { |j| states.include?(j["state"]) }
    end
  end

  # Exclude waiter/trigger jobs
  jobs = jobs.reject { |j| %w[waiter trigger].include?(j["type"]) }

  if jobs.empty?
    state_desc = states&.any? ? " with state: #{states.join(', ')}" : ""
    return "No jobs#{state_desc} in build ##{build['number']}"
  end

  output = []
  state_desc = states&.any? ? " (#{states.join(', ')})" : ""
  output << "Jobs in build ##{build['number']}#{state_desc}:"
  output << ""

  jobs.each do |job|
    output << "#{job['name'] || '(unnamed)'}"
    output << "  ID: #{job['id']}"
    output << "  State: #{job['state']}"
    output << "  Command: #{job['command']&.lines&.first&.strip}" if job["command"]
    output << "  URL: #{job['web_url']}"
    output << ""
  end

  output << "Total: #{jobs.length} job(s)"
  output.join("\n")
end

def parse_args(args)
  options = { org: nil, pipeline: nil, number: nil, states: nil }
  positional = []

  i = 0
  while i < args.length
    case args[i]
    when "--state", "-s"
      options[:states] ||= []
      options[:states] << args[i + 1]
      i += 2
    else
      positional << args[i]
      i += 1
    end
  end

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

if options[:org].nil? || options[:pipeline].nil? || options[:number].nil?
  warn "Usage: #{$PROGRAM_NAME} <org/pipeline> <build_number> [--state STATE]"
  warn ""
  warn "Options:"
  warn "  --state, -s  Filter by job state (can be repeated)"
  warn "               Use 'failed' to include both failed and timed_out"
  warn ""
  warn "Examples:"
  warn "  #{$PROGRAM_NAME} buildkite/buildkite 12345                  # All jobs"
  warn "  #{$PROGRAM_NAME} buildkite/buildkite 12345 --state failed   # Failed jobs"
  warn "  #{$PROGRAM_NAME} buildkite/buildkite 12345 -s running       # Running jobs"
  exit 1
end

build = get_build(options[:org], options[:pipeline], options[:number])
puts format_jobs(build, states: options[:states])
