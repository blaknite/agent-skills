---
name: buildkite-pipelines
description: Query Buildkite Pipelines API for build status, failed jobs, and job logs. Use when checking CI/CD status, debugging failed builds, or tailing job logs.
---

# Buildkite Pipelines

Query Buildkite CI/CD pipelines using the `bk` CLI.

## Prerequisites

The `bk` CLI must be installed and configured. Run `bk configure` to set up authentication.

## Tips

- **Don't guess flags.** Run `bk <command> -h` to see available flags before attempting a command. The CLI has rich filtering support that isn't obvious from the command names alone.
- **Job names can be missing.** Use `(.name // .label // "unnamed")` in `jq` filters — some jobs only have a `label` field.
- **Blocked ≠ failed.** A `blocked` job is waiting for manual unblock (e.g. a deploy gate), not a CI failure. Filter these out when looking for actual errors: `select(.state == "failed" or .state == "timed_out")`.
- **Build URLs from Slack.** Buildkite URLs follow the pattern `https://buildkite.com/<org>/<pipeline>/builds/<number>`. Extract the org, pipeline slug, and build number directly from the URL.
- **Don't pipe to `head`.** Piping `bk build list` to `head` causes SIGPIPE (exit code 141) because the CLI's output stream closes early. Use `jq` slicing instead: `bk build list ... -o json | jq '.[0:5]'`.

## Commands

### Get Build Status

```bash
# Latest build on a branch
bk build list -p org/pipeline --branch my-feature --limit 1 -o json | jq '.[0] | {number, state, branch, web_url, jobs: (.jobs | group_by(.state) | map({(.[0].state): length}) | add)}'

# Specific build number
bk build view -p org/pipeline 12345 -o json | jq '{number, state, branch, web_url, jobs: (.jobs | group_by(.state) | map({(.[0].state): length}) | add)}'
```

### Filter Builds

`bk build list` supports powerful filtering. Most filters are **server-side** (fast), except `--duration` and `--message` which are client-side.

```bash
# Builds from the last hour
bk build list -p org/pipeline --since 1h -o json

# Builds in a date window
bk build list -p org/pipeline --since 24h --until 12h -o json

# Find build by commit SHA
bk build list -p org/pipeline --commit abc123def -o json

# Failed builds on main in the last day
bk build list -p org/pipeline --state failed --branch main --since 24h -o json

# Builds by a specific creator
bk build list -p org/pipeline --creator alice@company.com -o json

# Builds matching a message (client-side, slower)
bk build list -p org/pipeline --message "deploy" -o json

# Slow builds (client-side)
bk build list -p org/pipeline --duration ">20m" -o json

# Filter by meta-data
bk build list -p org/pipeline --meta-data env=production -o json
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

Note: Unlike other commands, `bk build watch` only accepts pipeline slug (not org/pipeline format).

```bash
# Watch build in real-time
bk build watch -p pipeline 12345

# Watch latest build on branch
bk build watch -p pipeline -b my-feature
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
   bk build watch -p pipeline -b my-branch
   ```

2. Find failed jobs:
   ```bash
   bk build list -p org/pipeline --branch my-branch --limit 1 -o json | jq '.[0].jobs[] | select(.state == "failed" or .state == "timed_out") | {id, name, web_url}'
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
