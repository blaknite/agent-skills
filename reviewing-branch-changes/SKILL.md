---
name: reviewing-branch-changes
description: "Gathers branch context (Linear issue, PR, build status) then performs a code review. Use when asked to review a branch, review current changes, or do a PR review with context."
---

# Reviewing Branch Changes

Gather full context for a branch and then perform a comprehensive code review. Combines context gathering with automated code review.

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
gh pr list --head <branch-name> --state all

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
bk build view -p buildkite/buildkite -b <branch-name> -o json | jq '{number, state, branch, web_url, jobs_summary: (.jobs | group_by(.state) | map({(.[0].state): length}) | add)}'
```

If the build has failures, list failed jobs:

```bash
bk build view -p buildkite/buildkite -b <branch-name> -o json | jq '.jobs[] | select(.state == "failed" or .state == "timed_out") | {id, name, web_url}'
```

### 6. Present Context Summary

Present a consolidated context summary before the review:

1. **Linear Issue**: Title, status, description, acceptance criteria
2. **Pull Request**: Title, description/body, status, review decision
3. **Build Status**: State (passed/failed/running), failed job count, link

### 7. Perform Code Review

Use the `oracle` tool to review the changes. First, get the list of changed files:

```bash
git fetch origin main
git diff origin/main...<branch-name> --name-only
```

Then consult the oracle for a comprehensive code review:

```
oracle(
  task: "Review the code changes on this branch for bugs, security issues, performance problems, and code quality concerns",
  context: "Branch: <branch-name>\nLinear Issue: <issue-title-and-description>\nPR Description: <pr-body>\n\nReview the diff output and changed files for issues.",
  files: ["path/to/changed/file1.rb", "path/to/changed/file2.rb"]
)
```

Include:
- The Linear issue description and PR body as context
- Key changed files (up to 10-15 most important files)
- Any specific areas of concern from the build status

### 8. Present Review Results

Present the oracle's findings in a clear format:

### Code Review Results

Summarize the key findings from the oracle, organized by severity:

**Critical/High Priority Issues:**
- Issue description with file:line reference and recommended fix

**Medium Priority Issues:**
- Issue description with file:line reference and recommended fix

**Low Priority/Suggestions:**
- Improvement suggestions

Then ask: "Would you like me to fix any of these issues?"

## Example Output

```
## Branch Review: feature/ENG-456-add-user-auth

### Context

#### Linear Issue: ENG-456
- **Title**: Add user authentication
- **Status**: In Progress
- **Description**: Implement JWT-based auth...

#### Pull Request: #1234
- **Title**: Add user authentication
- **Status**: Open
- **Reviews**: Changes requested (1/2)

#### Build: #5678
- **Status**: Passed
- **URL**: https://buildkite.com/...

### Code Review Results

**Critical/High Priority Issues:**
- **auth.rb:45**: Hardcoded secret found - secrets should be stored in environment variables

**Medium Priority Issues:**
- **user.rb:23**: Missing presence validation on email field - could allow invalid data

**Low Priority/Suggestions:**
- **auth.rb:12**: Long method (45 lines) - consider extracting helper methods for readability

Would you like me to fix any of these issues?
```
