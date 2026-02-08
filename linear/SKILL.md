---
name: linear
description: Manage Linear issues, projects, and milestones. Use when the user provides a linear.app URL, creating or updating issues, checking issue status, managing projects, or working with milestones. Do NOT use read_web_page for Linear URLs.
---

# Linear

Manage Linear issues, projects, and milestones using the `linear` CLI.

## Requirements

- `linear` CLI installed and authenticated (`linear auth`)
- `--team TEAM_KEY` required for most commands (create, list, update)

## Issues

```bash
# View issue
linear issue view ABC-123

# List/search issues (--sort is required: "priority" or "manual")
linear issue list --sort priority                    # Your unstarted issues
linear issue list --sort priority --state started    # By state
linear issue list --sort priority --project "Name"   # By project
linear issue list --sort priority --all-states -A    # All issues, all assignees

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

### Get Project Details (GraphQL API)

The CLI doesn't support fetching detailed project descriptions. Use the GraphQL API directly:

```bash
# Get auth token
LINEAR_TOKEN=$(linear auth token)

# Fetch project details (use slug from URL, e.g., a74ff3a2c8d4)
curl -s -X POST https://api.linear.app/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: $LINEAR_TOKEN" \
  -d '{"query": "{ project(id: \"PROJECT_SLUG\") { name description content state lead { name } startDate targetDate issues { nodes { identifier title state { name } priority } } } }"}'
```

- Project ID: Use the slug from the URL (e.g., `a74ff3a2c8d4` from `linear.app/buildkite/project/a74ff3a2c8d4`)
- `description`: Short text description
- `content`: Full rich-text project document
- `state`: String field (not an object—no subfields)

## Milestones

```bash
# List milestones
linear milestone list --project PROJECT-ID

# Create milestone
linear milestone create --project PROJECT-ID --name "Milestone" --target-date 2024-12-31

# Update milestone
linear milestone update MILESTONE-ID --name "New Name" --target-date 2025-01-15
```

### Assign Issue to Milestone (GraphQL API)

The CLI doesn't support assigning issues to milestones. Use the GraphQL API directly:

```bash
# Get auth token
LINEAR_TOKEN=$(linear auth token)

# Assign issue to milestone
curl -s -X POST https://api.linear.app/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: $LINEAR_TOKEN" \
  -d '{"query": "mutation { issueUpdate(id: \"ABC-123\", input: { projectMilestoneId: \"MILESTONE-UUID\" }) { success } }"}'
```

- Issue ID: Use team-prefixed identifier (e.g., `MDC-898`)
- Milestone ID: UUID returned when creating the milestone (e.g., `834feef4-7039-44a0-b9df-c8a0fadfb54b`)

## Tips

- State options: `triage`, `backlog`, `unstarted`, `started`, `completed`, `canceled`
- Priority: 1=urgent, 2=high, 3=medium, 4=low
- Run `linear <command> --help` for all available flags
