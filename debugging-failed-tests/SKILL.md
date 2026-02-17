---
name: debugging-failed-tests
description: "Debug failed tests using Buildkite Test Engine. Use when tests have failed in CI and you need to find which tests failed, get backtraces, and diagnose the issue."
---

# Debugging Failed Tests

Find and diagnose test failures from Buildkite Test Engine.

Load skills: using-buildkite

## Workflow

### 1. Find Test Runs

List runs for a suite, optionally filtering by build ID:

```bash
ruby scripts/list_runs.rb <org_slug> <suite_slug>
ruby scripts/list_runs.rb <org_slug> <suite_slug> --build-id <build_id>
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
