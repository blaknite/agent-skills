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

def get_build_with_test_engine(org, pipeline, number)
  api_get("/organizations/#{org}/pipelines/#{pipeline}/builds/#{number}?include_test_engine=true")
end

def get_run_details(org, suite_slug, run_id)
  api_get("/analytics/organizations/#{org}/suites/#{suite_slug}/runs/#{run_id}")
rescue
  nil
end

def format_test_runs(build)
  test_engine = build["test_engine"] || {}
  runs = test_engine["runs"] || []
  org_slug = build.dig("pipeline", "organization", "slug") || "buildkite"

  if runs.empty?
    return "No test runs found for build ##{build['number']}"
  end

  output = []
  output << "Test runs for build ##{build['number']}:"
  output << ""

  runs.each do |run|
    suite_slug = run.dig("suite", "slug") || "unknown"
    run_id = run["id"]

    # Fetch full run details
    details = get_run_details(org_slug, suite_slug, run_id)

    if details
      state = details["state"]&.upcase || "UNKNOWN"
      result = details["result"]&.upcase || "PENDING"
      passed = details["passed_count"] || 0
      failed = details["failed_count"] || 0
      skipped = details["skipped_count"] || 0
      total = passed + failed + skipped

      output << "#{suite_slug}"
      output << "  Run ID: #{run_id}"
      output << "  State: #{state}, Result: #{result}"
      output << "  Tests: #{passed} passed, #{failed} failed, #{skipped} skipped (#{total} total)"
      output << "  Suite: #{org_slug}/#{suite_slug}"
    else
      output << "#{suite_slug}"
      output << "  Run ID: #{run_id}"
      output << "  Suite: #{org_slug}/#{suite_slug}"
    end

    output << ""
  end

  output << "Total: #{runs.length} test run(s)"
  output.join("\n")
end

def parse_args(args)
  options = { org: nil, pipeline: nil, number: nil }
  positional = []

  args.each do |arg|
    positional << arg
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
  warn "Usage: #{$PROGRAM_NAME} <org/pipeline> <build_number>"
  warn ""
  warn "Shows test engine runs associated with a build."
  warn ""
  warn "Examples:"
  warn "  #{$PROGRAM_NAME} buildkite/buildkite 174608"
  exit 1
end

build = get_build_with_test_engine(options[:org], options[:pipeline], options[:number])
puts format_test_runs(build)
