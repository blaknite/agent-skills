---
name: debugging-failed-builds
description: "Debug failed Buildkite builds by watching builds, finding failed jobs, reading logs, and identifying errors. Use when a build has failed or you need to diagnose CI failures."
---

# Debugging Failed Builds

Diagnose and fix failed Buildkite builds.

Load skills: using-buildkite

## Workflow

### 1. Watch the Build

Wait for the build to finish (or start failing):

```bash
bk build watch -p pipeline -b my-branch
```

### 2. Find Failed Jobs

```bash
bk build list -p org/pipeline --branch my-branch --limit 1 -o json | jq '.[0].jobs[] | select(.state == "failed" or .state == "timed_out") | {id, name, web_url}'
```

### 3. Read Job Logs

For each failed job, fetch the log and look for errors:

```bash
bk job log <job-id> -p org/pipeline -b <build-number> --no-timestamps | tail -n 200
```

### 4. Search for Errors

```bash
bk job log <job-id> -p org/pipeline -b <build-number> --no-timestamps | grep -i error -C 3
```

### 5. Check for Test Failures

If the failed job ran tests, get the test run IDs and hand off to the `debugging-failed-tests` skill:

```bash
ruby scripts/test_runs.rb org/pipeline <build_number>
```
