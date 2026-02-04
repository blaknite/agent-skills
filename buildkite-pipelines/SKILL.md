---
name: buildkite-pipelines
description: Query Buildkite Pipelines API for build status, failed jobs, and job logs. Use when checking CI/CD status, debugging failed builds, or tailing job logs.
---

# Buildkite Pipelines API

Query Buildkite CI/CD pipelines using the REST API.

## Prerequisites

Credentials are loaded from `~/.config/buildkite/credentials.yml`:

```yaml
buildkite_api_token: "your-token-here"
```

## Available Scripts

### Get Build Status

```bash
ruby scripts/build_status.rb <org/pipeline> [build_number] [--branch BRANCH]
```

Shows build state, jobs summary, and web URL. Omit build number to get the latest build.

### List Jobs

```bash
ruby scripts/list_jobs.rb <org/pipeline> <build_number> [--state STATE]
```

Lists jobs with ID, state, command, and URL. Filter by state with `--state` (can be repeated). Use `--state failed` to include both failed and timed_out jobs.

### Get Job Log

```bash
ruby scripts/job_log.rb <org/pipeline> <build_number> <job_id> [--tail N]
```

Retrieves raw log output. Use `--tail N` to show only the last N lines.

### Search Job Logs

```bash
ruby scripts/search_logs.rb <org/pipeline> <build_number> <job_id> <pattern>
```

Searches log for matching lines (case-insensitive) with context.

### Test Runs

```bash
ruby scripts/test_runs.rb <org/pipeline> <build_number>
```

Shows Test Engine runs for a build with run IDs, state, and suite slugs. Use run IDs with the test-engine skill to get failed tests.

### Wait for Build

```bash
ruby scripts/wait_for_build.rb <org/pipeline> [--branch BRANCH] [--timeout SECONDS]
```

Polls until a build exists and reaches a terminal state (passed/failed/canceled) or starts failing. Exits 0 on pass, 1 on failure/timeout.

## Common Workflows

### Debug a failed build

1. Wait for the build to finish or start failing
2. List failed jobs to get job IDs
3. Fetch logs or search for error patterns

### Monitor latest build

```bash
ruby scripts/build_status.rb buildkite/buildkite
ruby scripts/build_status.rb buildkite/buildkite --branch my-feature
```


