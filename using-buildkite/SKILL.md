---
name: using-buildkite
description: "Query Buildkite Pipelines API for build status, failed jobs, and job logs, and query Buildkite Test Engine API for failed test executions and traces. Use when checking CI/CD status, debugging builds, or analyzing test results."
---

# Buildkite

Reference for the Buildkite CLI (`bk`) and Test Engine API scripts.

## Prerequisites

- The `bk` CLI must be installed and configured. Run `bk configure` to set up authentication.
- A `BUILDKITE_API_TOKEN` environment variable with Test Engine read access (for test engine scripts).

## Pipelines CLI

### Get Build Status

```bash
# Latest build on a branch
bk build list -p org/pipeline --branch my-feature --limit 1 -o json | jq '.[0] | {number, state, branch, web_url, jobs: (.jobs | group_by(.state) | map({(.[0].state): length}) | add)}'

# Specific build number
bk build view -p org/pipeline 12345 -o json | jq '{number, state, branch, web_url, jobs: (.jobs | group_by(.state) | map({(.[0].state): length}) | add)}'
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

**Important:** Job logs contain heavy use of ANSI escape/control characters (cursor movement, progress bars, color codes, line overwrites). These can make output unreadable or hide content. Always use `cat -v` to make control characters visible, then filter the noise:

```bash
# Get full job log with control characters made visible
bk job log <job-id> -p org/pipeline -b 12345 --no-timestamps | cat -v

# Strip timestamps
bk job log <job-id> -p org/pipeline -b 12345 --no-timestamps

# Last N lines (with control chars visible)
bk job log <job-id> -p org/pipeline -b 12345 --no-timestamps | cat -v | tail -n 100
```

### Search Job Logs

```bash
# Search for pattern with context
bk job log <job-id> -p org/pipeline -b 12345 --no-timestamps | grep -i "error" -C 2

# Search for multiple patterns
bk job log <job-id> -p org/pipeline -b 12345 --no-timestamps | grep -iE "(error|failed|exception)"
```

### Watch Build Progress

Note: Unlike other commands, `bk build watch` only accepts pipeline slug (not org/pipeline format).

```bash
# Watch build in real-time
bk build watch -p pipeline 12345

# Watch latest build on branch
bk build watch -p pipeline -b my-feature
```
