---
name: linear-issues
description: Query Linear issue contents. Use when fetching Linear issue details, getting issue descriptions, or checking issue status.
---

# Linear Issues

Query and manage Linear issues using the `linctl` CLI tool.

## Requirements

- `linctl` must be installed and authenticated (run `linctl auth` to authenticate)

## Available Commands

### Get Issue Details

#### Summary View (filtered fields)

```bash
linctl issue get ABC-123 --json | jq '{
  identifier,
  title,
  description,
  priority: .priorityLabel,
  status: .state.name,
  assignee: .assignee.name,
  team: .team.name,
  url,
  project: .project.name
}'
```

#### Full View (all details)

```bash
linctl issue get ABC-123 --json
```

### List Issues

List issues with optional filters:

```bash
linctl issue list --team ENG --json
linctl issue list --assignee me --state "In Progress" --json
linctl issue list --priority 1 --json  # Urgent priority
linctl issue list --newer-than 2_weeks_ago --json
linctl issue list --include-completed --json  # Include done/canceled issues
```

Arguments:
- `--team TEAM_KEY`: Filter by team key
- `--assignee EMAIL|me`: Filter by assignee
- `--state STATE_NAME`: Filter by state name
- `--priority N`: Filter by priority (0=None, 1=Urgent, 2=High, 3=Normal, 4=Low)
- `--newer-than DURATION`: Filter by creation time (e.g., `2_weeks_ago`, `3_months_ago`)
- `--include-completed`: Include completed and canceled issues
- `--limit N`: Maximum number of issues (default 50)
- `--json`: Output as JSON
