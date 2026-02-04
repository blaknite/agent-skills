---
name: gathering-branch-context
description: "Gathers full context for a branch: Linear issue, PR details, and latest build status. Use when starting work on a branch or needing a complete status overview."
---

# Gathering Branch Context

Quickly gather all context for a branch to start working from a known point. Combines Linear issue details, GitHub PR information, and Buildkite build status.

## Prerequisites

- `linctl` CLI installed and authenticated (`linctl auth`)
- GitHub CLI (`gh`) installed and authenticated (`gh auth status`)
- Buildkite credentials in `~/.config/buildkite/credentials.yml`

## Workflow

### 1. Determine the Branch

Use the current branch or ask the user:

```bash
git branch --show-current
```

### 2. Extract Linear Issue ID

Parse the branch name for a Linear issue ID (e.g., `ABC-123` or `abc-123`):

```bash
# Common patterns: feature/ABC-123-description, abc-123/description, ABC-123-description
# Use -i for case-insensitive matching, then uppercase for linctl
git branch --show-current | grep -oiE '[a-z]+-[0-9]+' | head -1 | tr '[:lower:]' '[:upper:]'
```

### 3. Fetch Linear Issue Details

If an issue ID is found:

```bash
linctl issue get ABC-123
```

### 4. Find and Read Pull Request

```bash
# Find PRs for the branch
gh pr list --head <branch-name> --state all

# If PR exists, read details
gh pr view <pr-number>

# Check PR review status
gh pr view <pr-number> --json title,state,reviewDecision,reviews
```

### 5. Get Build Status

Use the buildkite-pipelines skill scripts to check the latest build:

```bash
# Get latest build for the branch (adjust org/pipeline as needed)
ruby ~/.config/agents/skills/buildkite-pipelines/scripts/build_status.rb buildkite/buildkite --branch <branch-name>
```

If the build has failures, list failed jobs:

```bash
ruby ~/.config/agents/skills/buildkite-pipelines/scripts/list_jobs.rb buildkite/buildkite <build_number> --state failed
```

## Output Summary

Present a consolidated summary:

1. **Linear Issue**: Title, status, description, acceptance criteria
2. **Pull Request**: Title, status, review decision, open comments
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

### Build: #5678
- **Status**: Failed
- **Failed Jobs**: 2 (rspec, eslint)
- **URL**: https://buildkite.com/...
```
