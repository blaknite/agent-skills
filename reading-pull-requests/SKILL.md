---
name: reading-pull-requests
description: Finds and reads pull requests for a given branch using the GitHub CLI (gh). Use when asked to find PRs, review PR details, or check PR status for a branch.
---

# Reading Pull Requests

Finds and displays pull request information for a given branch using the GitHub CLI.

## Prerequisites

- GitHub CLI (`gh`) must be installed and authenticated
- Run `gh auth status` to verify authentication

## Finding PRs for a Branch

To find pull requests associated with a branch:

```bash
gh pr list --head <branch-name>
```

To include closed/merged PRs:

```bash
gh pr list --head <branch-name> --state all
```

## Reading PR Details

Once you have a PR number, read its details:

### Summary View (filtered fields)

```bash
gh pr view <pr-number> --json number,title,body,state,reviewDecision,mergedAt,url,author,reviews | jq '{
  number,
  title,
  body,
  state,
  reviewDecision,
  mergedAt,
  url,
  author: .author.login,
  reviews: [.reviews[] | {author: .author.login, state}]
}'
```

### Full View (all details)

```bash
# Human-readable summary
gh pr view <pr-number>

# Full JSON with all fields
gh pr view <pr-number> --json number,title,body,state,author,reviewDecision,reviews,comments,labels,assignees,milestone,mergedAt,mergedBy,closedAt,createdAt,updatedAt,url,headRefName,baseRefName,isDraft,additions,deletions,changedFiles

# View PR diff
gh pr diff <pr-number>

# View PR comments
gh pr view <pr-number> --comments
```

## Workflow

1. Ask the user for the branch name (or use the current branch with `git branch --show-current`)
2. Run `gh pr list --head <branch-name> --state all` to find associated PRs
3. If PRs are found, use `gh pr view <pr-number>` to read details
4. Present the PR information to the user

## Viewing PR Checks Status

To see the status of CI checks on a PR:

```bash
# View checks summary
gh pr checks <pr-number>

# Watch checks in real-time until they complete
gh pr checks <pr-number> --watch
```

## Useful Options

- `--repo <owner/repo>`: Specify repository if not in a git directory
- `--json <fields>`: Output as JSON with specific fields
- `--jq <expression>`: Filter JSON output
