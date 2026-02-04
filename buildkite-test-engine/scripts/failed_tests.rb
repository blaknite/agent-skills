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

def fetch_api(path)
  token = ENV["BUILDKITE_API_TOKEN"]
  abort "Error: BUILDKITE_API_TOKEN environment variable is required" unless token

  uri = URI("https://api.buildkite.com#{path}")

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

def fetch_all_pages(base_path)
  results = []
  page = 1

  loop do
    separator = base_path.include?("?") ? "&" : "?"
    path = "#{base_path}#{separator}page=#{page}&per_page=100"
    data = fetch_api(path)

    break if data.empty?

    results.concat(data)
    page += 1

    break if data.length < 100
  end

  results
end

def main
  expanded = ARGV.delete("--expanded") || ARGV.delete("-e")

  if ARGV.length < 2
    abort "Usage: #{$PROGRAM_NAME} <org/suite> <run_id> [--expanded]"
  end

  if ARGV[0].include?("/")
    org_slug, suite_slug = ARGV[0].split("/", 2)
    run_id = ARGV[1]
  else
    if ARGV.length < 3
      abort "Usage: #{$PROGRAM_NAME} <org/suite> <run_id> [--expanded]"
    end
    org_slug = ARGV[0]
    suite_slug = ARGV[1]
    run_id = ARGV[2]
  end

  path = "/v2/analytics/organizations/#{org_slug}/suites/#{suite_slug}/runs/#{run_id}/failed_executions"
  path += "?include_failure_expanded=true" if expanded
  failures = fetch_all_pages(path)

  if failures.empty?
    puts "No failed tests in this run"
    return
  end

  puts "Failed Tests for Run #{run_id}"
  puts "-" * 60

  failures.each_with_index do |failure, index|
    name = failure["test_name"] || failure["name"] || "Unknown"
    test_id = failure["test_id"]
    location = failure["location"]
    failure_reason = failure["failure_reason"]
    failure_expanded = failure["failure_expanded"]

    puts ""
    puts "#{index + 1}. #{name}"
    puts "   Location: #{location}" if location
    puts "   Test ID: #{test_id}" if test_id

    if failure_reason
      puts "   Failure: #{failure_reason}"
    end

    if failure_expanded&.any?
      failure_expanded.each do |detail|
        if detail["backtrace"]&.any?
          puts "   Backtrace:"
          detail["backtrace"].first(10).each do |line|
            puts "     #{line}"
          end
          puts "     ... (#{detail['backtrace'].length - 10} more)" if detail["backtrace"].length > 10
        end

        if detail["expanded"]&.any?
          puts "   Details:"
          detail["expanded"].first(15).each do |line|
            puts "     #{line}"
          end
          puts "     ... (truncated)" if detail["expanded"].length > 15
        end
      end
    end
  end

  puts ""
  puts "Total: #{failures.length} failed test(s)"
end

main
