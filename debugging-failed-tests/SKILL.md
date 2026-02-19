---
name: debugging-failed-tests
description: "Debug failed tests using Buildkite Test Engine. Use when tests have failed in CI and you need to find which tests failed, get backtraces, and diagnose the issue."
---

# Debugging Failed Tests

Find and diagnose test failures from Buildkite Test Engine.

Load skills: using-buildkite

## Workflow

### 1. Find Test Runs

Given a build number and pipeline, list all test engine runs for that build:

```bash
ruby scripts/list_runs.rb <org/pipeline> <build_number>
```

This uses the Builds API with `include_test_engine=true` to find all test engine runs associated with the build, then fetches details (pass/fail counts) for each run.

To browse recent runs for a specific suite instead:

```bash
ruby scripts/list_runs.rb <org/suite> --recent
```

### 2. Get Failed Tests

```bash
ruby scripts/failed_tests.rb <org/suite> <run_id>
```

### 3. Get Full Details

Use `--expanded` for full backtraces and error details:

```bash
ruby scripts/failed_tests.rb <org/suite> <run_id> --expanded
```

### 4. Diagnose

Read the failing test files and the code under test to understand what went wrong. Look for:
- Recent changes that could have caused the failure
- Flaky test patterns (intermittent failures, timing issues)
- Environment or dependency issues
