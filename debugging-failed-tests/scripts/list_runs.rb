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

def list_runs_for_build(org_slug, pipeline_slug, build_number)
  path = "/v2/organizations/#{org_slug}/pipelines/#{pipeline_slug}/builds/#{build_number}"
  build = fetch_api(path, include_test_engine: true, exclude_jobs: true)

  runs = build.dig("test_engine", "runs") || []

  if runs.empty?
    puts "No test engine runs found for build ##{build_number}"
    return
  end

  puts "Test Engine Runs for #{org_slug}/#{pipeline_slug} build ##{build_number}"
  puts "-" * 60

  runs.each do |run|
    suite_slug = run.dig("suite", "slug") || "unknown"
    run_details = fetch_api("/v2/analytics/organizations/#{org_slug}/suites/#{suite_slug}/runs/#{run["id"]}")

    state = run_details["state"]&.upcase || "UNKNOWN"
    result = run_details["result"]&.upcase || "N/A"
    passed = run_details["passed_count"] || 0
    failed = run_details["failed_count"] || 0

    puts ""
    puts "Suite: #{suite_slug}"
    puts "  Run ID: #{run["id"]}"
    puts "  State: #{state} | Result: #{result}"
    puts "  Passed: #{passed} | Failed: #{failed}"
    puts "  Branch: #{run_details["branch"] || "N/A"}"
    puts "  Commit: #{run_details["commit_sha"]&.slice(0, 8) || "N/A"}"
  end
end

def list_runs_for_suite(org_slug, suite_slug)
  path = "/v2/analytics/organizations/#{org_slug}/suites/#{suite_slug}/runs"
  runs = fetch_api(path)

  if runs.empty?
    puts "No runs found for #{org_slug}/#{suite_slug}"
    return
  end

  puts "Recent Runs for #{org_slug}/#{suite_slug}"
  puts "-" * 60

  runs.each do |run|
    state = run["state"]&.upcase || "UNKNOWN"
    result = run["result"]&.upcase || "N/A"
    passed = run["passed_count"] || 0
    failed = run["failed_count"] || 0

    puts ""
    puts "Run ID: #{run["id"]}"
    puts "  State: #{state} | Result: #{result}"
    puts "  Passed: #{passed} | Failed: #{failed}"
    puts "  Branch: #{run["branch"] || "N/A"}"
    puts "  Commit: #{run["commit_sha"]&.slice(0, 8) || "N/A"}"
    puts "  Created: #{run["created_at"]}"
  end
end

def main
  if ARGV.empty?
    abort <<~USAGE
      Usage:
        #{$PROGRAM_NAME} <org/pipeline> <build_number>    # List test engine runs for a build (recommended)
        #{$PROGRAM_NAME} <org/suite> --recent              # List recent runs for a suite
    USAGE
  end

  unless ARGV[0].include?("/")
    abort "Error: first argument must be in org/pipeline or org/suite format"
  end

  org_slug, slug = ARGV[0].split("/", 2)

  if ARGV.include?("--recent")
    list_runs_for_suite(org_slug, slug)
  elsif ARGV[1] && ARGV[1] =~ /\A\d+\z/
    list_runs_for_build(org_slug, slug, ARGV[1])
  else
    abort <<~USAGE
      Usage:
        #{$PROGRAM_NAME} <org/pipeline> <build_number>    # List test engine runs for a build (recommended)
        #{$PROGRAM_NAME} <org/suite> --recent              # List recent runs for a suite
    USAGE
  end
end

main
