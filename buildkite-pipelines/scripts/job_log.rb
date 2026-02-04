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

def api_get_log(path)
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
    warn "Error: Not found. Check org, pipeline, build number, and job ID."
    exit 1
  else
    warn "Error: API returned #{response.code}: #{response.body}"
    exit 1
  end
end

def strip_ansi(text)
  text
    .gsub(/\e\[[0-9;]*[mGKHF]/, "")      # Standard ANSI escape sequences
    .gsub(/\e_bk;[^\a]*\a/, "")           # Buildkite timestamp markers
    .gsub(/\r\r\n/, "\n")                 # Normalize line endings
    .gsub(/\r\n/, "\n")
    .gsub(/\r/, "")
end

def parse_args(args)
  tail_lines = nil
  positional = []

  i = 0
  while i < args.length
    if args[i] == "--tail" && args[i + 1]
      tail_lines = args[i + 1].to_i
      i += 2
    elsif args[i].start_with?("--tail=")
      tail_lines = args[i].split("=", 2).last.to_i
      i += 1
    else
      positional << args[i]
      i += 1
    end
  end

  [positional, tail_lines]
end

positional, tail_lines = parse_args(ARGV)

if positional.length < 3
  warn "Usage: #{$PROGRAM_NAME} <org/pipeline> <build_number> <job_id> [--tail N]"
  warn ""
  warn "Examples:"
  warn "  #{$PROGRAM_NAME} buildkite/buildkite 12345 abc-123-def"
  warn "  #{$PROGRAM_NAME} buildkite/buildkite 12345 abc-123-def --tail 100"
  exit 1
end

if positional[0].include?("/")
  org, pipeline = positional[0].split("/", 2)
  build_number = positional[1]
  job_id = positional[2]
else
  if positional.length < 4
    warn "Usage: #{$PROGRAM_NAME} <org/pipeline> <build_number> <job_id> [--tail N]"
    exit 1
  end
  org = positional[0]
  pipeline = positional[1]
  build_number = positional[2]
  job_id = positional[3]
end

path = "/organizations/#{org}/pipelines/#{pipeline}/builds/#{build_number}/jobs/#{job_id}/log"
log_data = api_get_log(path)

content = log_data["content"] || ""
content = strip_ansi(content)

if tail_lines
  lines = content.lines
  content = lines.last(tail_lines).join
end

puts content
