---
name: gathering-branch-context
description: "Gathers full context for a branch: Linear issue, PR details, and latest build status. Use when starting work on a branch or needing a complete status overview."
---

# Gathering Branch Context

Quickly gather all context for a branch to start working from a known point. Combines Linear issue details, GitHub PR information, and Buildkite build status.

## Prerequisites

- `linctl` CLI installed and authenticated (`linctl auth`)
- GitHub CLI (`gh`) installed and authenticated (`gh auth status`)
- Buildkite CLI (`bk`) installed and configured (`bk configure`)

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
linctl issue get ABC-123 --json | jq '{
  identifier,
  title,
  description,
  priority: .priorityLabel,
  status: .state.name,
  assignee: .assignee.name,
  url,
  project: .project.name
}'
```

### 4. Find and Read Pull Request

```bash
# Find PRs for the branch
gh pr list --head <branch-name> --state all

# If PR exists, get details with jq filtering (include body for full context)
gh pr view <pr-number> --json number,title,body,state,reviewDecision,mergedAt,url,reviews | jq '{
  number,
  title,
  body,
  state,
  reviewDecision,
  mergedAt,
  url,
  reviews: [.reviews[] | {author: .author.login, state}]
}'
```

### 5. Get Build Status

```bash
# Get build summary for the branch (adjust org/pipeline as needed)
bk build view -p buildkite/buildkite -b <branch-name> -o json | jq '{number, state, branch, web_url, jobs_summary: (.jobs | group_by(.state) | map({(.[0].state): length}) | add)}'
```

If the build has failures, list failed jobs:

```bash
bk build view -p buildkite/buildkite -b <branch-name> -o json | jq '.jobs[] | select(.state == "failed" or .state == "timed_out") | {id, name, web_url}'
```

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
