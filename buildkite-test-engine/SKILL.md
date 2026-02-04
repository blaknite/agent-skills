---
name: buildkite-test-engine
description: Query Buildkite Test Engine API for failed test executions and traces. Use when debugging test failures, finding flaky tests, or analyzing test results.
---

# Buildkite Test Engine

Query the Buildkite Test Engine REST API to analyze test failures, find flaky tests, and debug test execution issues.

## Authentication

All scripts require a `BUILDKITE_API_TOKEN` environment variable with Test Engine read access.

## Available Scripts

### List Runs

List recent test runs for a suite:

```bash
ruby scripts/list_runs.rb <org_slug> <suite_slug> [--build-id BUILD_ID]
```

Example:
```bash
ruby scripts/list_runs.rb buildkite my-suite
ruby scripts/list_runs.rb buildkite my-suite --build-id abc123
```

### Get Failed Tests

Get failed test executions from a specific run:

```bash
ruby scripts/failed_tests.rb <org/suite> <run_id> [--expanded]
```

Use `--expanded` to include full backtraces and error details.

Example:
```bash
ruby scripts/failed_tests.rb buildkite/my-suite 01234567-89ab-cdef-0123-456789abcdef
ruby scripts/failed_tests.rb buildkite/my-suite 01234567-89ab-cdef-0123-456789abcdef --expanded
```

## Workflow

1. Use `list_runs.rb` to find recent runs, optionally filtering by build ID
2. Use `failed_tests.rb` with a run ID to see which tests failed
3. Use `--expanded` to get full backtraces for debugging

## API Reference

Base URL: `https://api.buildkite.com`

- Runs: `GET /v2/analytics/organizations/{org}/suites/{suite}/runs`
- Failures: `GET /v2/analytics/organizations/{org}/suites/{suite}/runs/{run_id}/failures`
- Test details: `GET /v2/analytics/organizations/{org}/suites/{suite}/tests/{test_id}`
