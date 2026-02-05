---
name: linear
description: Manage Linear issues, projects, and milestones. Use when creating or updating issues, checking issue status, managing projects, or working with milestones.
---

# Linear

Manage Linear issues, projects, and milestones using the `linear` CLI.

## Requirements

- `linear` CLI installed and authenticated (`linear auth`)
- `--team TEAM_KEY` required for create commands unless configured via `linear config`

## Issues

```bash
# View issue
linear issue view ABC-123
linear issue view ABC-123 --json

# List/search issues
linear issue list                                    # Your unstarted issues
linear issue list --state started                    # By state
linear issue list --project "Project Name"           # By project
linear issue list --all-states -A                    # All issues, all assignees

# Create issue
linear issue create -t "Title" --team ENG --project "Project Name"

# Update issue status
linear issue update ABC-123 -s "In Progress"

# Update other fields
linear issue update ABC-123 -t "New title" -a self --priority 1
```

## Projects

```bash
# List projects
linear project list
linear project list --team ENG

# Create project
linear project create -n "Project Name" -t ENG -l @me -s started
```

## Milestones

```bash
# List milestones
linear milestone list --project PROJECT-ID

# Create milestone
linear milestone create --project PROJECT-ID --name "Milestone" --target-date 2024-12-31

# Update milestone
linear milestone update MILESTONE-ID --name "New Name" --target-date 2025-01-15
```

## Tips

- State options: `triage`, `backlog`, `unstarted`, `started`, `completed`, `canceled`
- Priority: 1=urgent, 2=high, 3=medium, 4=low
- Run `linear <command> --help` for all available flags
