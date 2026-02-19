---
name: gathering-context
description: "Gathers full context for a branch: Linear issue, PR details, and latest build status. Use when starting work on a branch or needing a complete status overview."
---

# Gathering Branch Context

Quickly gather all context for a branch to start working from a known point. Combines Linear issue details, GitHub PR information, and Buildkite build status.

Load skills: using-linear, reading-pull-requests, debugging-failed-builds

## Workflow

### 1. Determine the Branch

Use the current branch or ask the user:

```bash
git branch --show-current
```

### 2. Find and Read Pull Request

Load the `reading-pull-requests` skill and use it to find and read any PR for the branch.

The reading-pull-requests skill covers finding PRs by branch name, reading PR details (including body, reviews, and review decision), and viewing PR checks.

### 3. Fetch Linear Issue Details

Look for a Linear issue ID (e.g., `ABC-123`) in the branch name, PR title, or PR body. Check all sources, extract any match using the `[a-z]+-[0-9]+` pattern, and uppercase it.

```bash
# Common patterns: feature/ABC-123-description, abc-123/description, ABC-123-description
# Use -i for case-insensitive matching, then uppercase for linear CLI
git branch --show-current | grep -oiE '[a-z]+-[0-9]+' | head -1 | tr '[:lower:]' '[:upper:]'
```

If an issue ID was found, load the `using-linear` skill and use it to view the issue.

### 4. Get Build Status

Load the `debugging-failed-builds` skill and use it to get the latest build for the branch.

If the build has failures, use the debugging-failed-builds skill's workflow to list failed jobs and optionally fetch their logs.

## Output Summary

Present a consolidated summary:

1. **Linear Issue**: Title, status, description, acceptance criteria
2. **Pull Request**: Title, description/body, status, review decision, open comments
3. **Build Status**: State (passed/failed/running), failed job count, link

## Example

For branch `feature/ENG-456-add-user-auth`:

```
## Branch Context: feature/ENG-456-add-user-auth

### Linear Issue: ENG-456
- **Title**: Add user authentication
- **Status**: In Progress
- **Description**: Implement JWT-based auth...

### Pull Request: #1234
- **Title**: Add user authentication
- **Status**: Open
- **Reviews**: Approved (2/2)
- **Comments**: 3 unresolved
- **Description**: Implements JWT-based authentication...

### Build: #5678
- **Status**: Failed
- **Failed Jobs**: 2 (rspec, eslint)
- **URL**: https://buildkite.com/...
```
