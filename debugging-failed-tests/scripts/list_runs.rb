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

def fetch_api(path, params = {})
  token = ENV["BUILDKITE_API_TOKEN"]
  abort "Error: BUILDKITE_API_TOKEN environment variable is required" unless token

  uri = URI("https://api.buildkite.com#{path}")
  uri.query = URI.encode_www_form(params) unless params.empty?

  request = Net::HTTP::Get.new(uri)
  request["Authorization"] = "Bearer #{token}"
  request["Accept"] = "application/json"

  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end

  case response
  when Net::HTTPSuccess
    JSON.parse(response.body)
  else
    abort "API Error: #{response.code} - #{response.body}"
  end
end

def main
  if ARGV.length < 1
    abort "Usage: #{$PROGRAM_NAME} <org/suite> [--build-id BUILD_ID]"
  end

  if ARGV[0].include?("/")
    org_slug, suite_slug = ARGV[0].split("/", 2)
  else
    if ARGV.length < 2
      abort "Usage: #{$PROGRAM_NAME} <org/suite> [--build-id BUILD_ID]"
    end
    org_slug = ARGV[0]
    suite_slug = ARGV[1]
  end

  params = {}
  if ARGV.include?("--build-id")
    build_id_index = ARGV.index("--build-id") + 1
    if build_id_index < ARGV.length
      params[:build_id] = ARGV[build_id_index]
    else
      abort "Error: --build-id requires a value"
    end
  end

  path = "/v2/analytics/organizations/#{org_slug}/suites/#{suite_slug}/runs"
  runs = fetch_api(path, params)

  if runs.empty?
    puts "No runs found"
    return
  end

  puts "Recent Runs for #{org_slug}/#{suite_slug}"
  puts "-" * 60

  runs.each do |run|
    state = run["state"]&.upcase || "UNKNOWN"
    result = run["result"]&.upcase || "N/A"
    passed = run["passed_count"] || 0
    failed = run["failed_count"] || 0
    created = run["created_at"]

    puts ""
    puts "Run ID: #{run["id"]}"
    puts "  State: #{state} | Result: #{result}"
    puts "  Passed: #{passed} | Failed: #{failed}"
    puts "  Branch: #{run["branch"] || "N/A"}"
    puts "  Commit: #{run["commit_sha"]&.slice(0, 8) || "N/A"}"
    puts "  Created: #{created}"
  end
end

main
