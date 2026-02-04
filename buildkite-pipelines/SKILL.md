---
name: buildkite-pipelines
description: Query Buildkite Pipelines API for build status, failed jobs, and job logs. Use when checking CI/CD status, debugging failed builds, or tailing job logs.
---

# Buildkite Pipelines

Query Buildkite CI/CD pipelines using the `bk` CLI.

## Prerequisites

The `bk` CLI must be installed and configured. Run `bk configure` to set up authentication.

## Commands

### Get Build Status

```bash
# Build summary (number, state, branch, URL, job counts)
bk build view -p org/pipeline -o json | jq '{number, state, branch, web_url, jobs: (.jobs | group_by(.state) | map({(.[0].state): length}) | add)}'

# Specific build number
bk build view -p org/pipeline 12345 -o json | jq '{number, state, branch, web_url, jobs: (.jobs | group_by(.state) | map({(.[0].state): length}) | add)}'

# Latest build on a specific branch
bk build view -p org/pipeline -b my-feature -o json | jq '{number, state, branch, web_url, jobs: (.jobs | group_by(.state) | map({(.[0].state): length}) | add)}'
```

### List Jobs

Jobs are included in build view output. Use JSON output and `jq` to filter:

```bash
# All jobs in a build
bk build view -p org/pipeline 12345 -o json | jq '.jobs[] | {id, name, state}'

# Failed jobs only (includes timed_out)
bk build view -p org/pipeline 12345 -o json | jq '.jobs[] | select(.state == "failed" or .state == "timed_out") | {id, name, state, web_url}'

# Running jobs
bk build view -p org/pipeline 12345 -o json | jq '.jobs[] | select(.state == "running") | {id, name}'
```

### Get Job Log

```bash
# Get full job log
bk job log <job-id> -p org/pipeline -b 12345

# Strip timestamps
bk job log <job-id> -p org/pipeline -b 12345 --no-timestamps

# Last N lines
bk job log <job-id> -p org/pipeline -b 12345 | tail -n 100
```

### Search Job Logs

```bash
# Search for pattern with context
bk job log <job-id> -p org/pipeline -b 12345 --no-timestamps | grep -i "error" -C 2

# Search for multiple patterns
bk job log <job-id> -p org/pipeline -b 12345 --no-timestamps | grep -iE "(error|failed|exception)"
```

### Watch Build Progress

```bash
# Watch build in real-time
bk build watch -p org/pipeline 12345

# Watch latest build on branch
bk build watch -p org/pipeline -b my-feature
```

### Test Runs

```bash
ruby scripts/test_runs.rb <org/pipeline> <build_number>
```

Shows Test Engine runs for a build with run IDs, state, and suite slugs. Use run IDs with the test-engine skill to get failed tests.

## Common Workflows

### Debug a failed build

1. Wait for the build to finish (or start failing):
   ```bash
   bk build watch -p org/pipeline -b my-branch
   ```

2. Find failed jobs:
   ```bash
   bk build view -p org/pipeline -b my-branch -o json | jq '.jobs[] | select(.state == "failed" or .state == "timed_out") | {id, name, web_url}'
   ```

3. Get logs for a failed job:
   ```bash
   bk job log <job-id> -p org/pipeline -b <build-number> --no-timestamps | tail -n 200
   ```

4. Search for errors:
   ```bash
   bk job log <job-id> -p org/pipeline -b <build-number> --no-timestamps | grep -i error -C 3
   ```

### Get test failures

```bash
# Get test run IDs
ruby scripts/test_runs.rb buildkite/buildkite 174608

# Then use test-engine skill with the run ID
```
