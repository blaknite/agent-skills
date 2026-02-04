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
CONTEXT_LINES = 2

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

def search_with_context(content, pattern, context_lines)
  lines = content.lines.map(&:chomp)
  regex = Regexp.new(pattern, Regexp::IGNORECASE)

  matches = []
  lines.each_with_index do |line, idx|
    matches << idx if line.match?(regex)
  end

  return [] if matches.empty?

  results = []
  printed_ranges = []

  matches.each do |match_idx|
    start_idx = [0, match_idx - context_lines].max
    end_idx = [lines.length - 1, match_idx + context_lines].min

    if printed_ranges.any? && printed_ranges.last.last >= start_idx - 1
      printed_ranges.last[1] = end_idx
    else
      printed_ranges << [start_idx, end_idx]
    end
  end

  printed_ranges.each_with_index do |range, range_idx|
    results << "---" if range_idx > 0

    (range[0]..range[1]).each do |idx|
      line = lines[idx]
      prefix = matches.include?(idx) ? ">" : " "
      results << "#{prefix} #{idx + 1}: #{line}"
    end
  end

  results
end

if ARGV.length < 4
  warn "Usage: #{$PROGRAM_NAME} <org/pipeline> <build_number> <job_id> <pattern>"
  warn ""
  warn "Example:"
  warn "  #{$PROGRAM_NAME} buildkite/buildkite 12345 abc-123-def 'error'"
  warn "  #{$PROGRAM_NAME} buildkite/buildkite 12345 abc-123-def 'undefined method'"
  exit 1
end

if ARGV[0].include?("/")
  org, pipeline = ARGV[0].split("/", 2)
  build_number = ARGV[1]
  job_id = ARGV[2]
  pattern = ARGV[3]
else
  if ARGV.length < 5
    warn "Usage: #{$PROGRAM_NAME} <org/pipeline> <build_number> <job_id> <pattern>"
    exit 1
  end
  org = ARGV[0]
  pipeline = ARGV[1]
  build_number = ARGV[2]
  job_id = ARGV[3]
  pattern = ARGV[4]
end

path = "/organizations/#{org}/pipelines/#{pipeline}/builds/#{build_number}/jobs/#{job_id}/log"
log_data = api_get_log(path)

content = log_data["content"] || ""
content = strip_ansi(content)

results = search_with_context(content, pattern, CONTEXT_LINES)

if results.empty?
  puts "No matches found for pattern: #{pattern}"
else
  puts "Matches for '#{pattern}':"
  puts ""
  puts results.join("\n")
end
