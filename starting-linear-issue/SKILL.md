---
name: starting-linear-issue
description: "Starts work on a Linear issue by gathering issue and project context, then creating a branch. Use when given a Linear issue URL or ID to begin implementation."
---

# Starting Linear Issue

Gather context for a Linear issue and prepare to begin work.

## Prerequisites

- `linear` CLI installed and authenticated (`linear auth`)

## Workflow

### 1. Get the Linear Issue

From URL or ID provided by user:

```bash
linear issue view ABC-123
```

### 2. Get Related Issues

Check for sub-issues and parent issues:

```bash
# Sub-issues (children)
linear issue list --sort priority --parent ABC-123

# If issue has a parent, view it
linear issue view <PARENT-ID>
```

Include any blocking/blocked relationships shown in the issue view output.

### 3. Get Project Context

If the issue belongs to a project:

```bash
linear project list --team <TEAM_KEY>
linear milestone list --project <PROJECT_ID>
```

### 4. Ask for Additional Context

After gathering details, ask:
> "Is there any other context you'd like to share before we proceed?"

### 5. Confirm Approach

After any additional context, ask:
> "How would you like me to proceed?"

### 6. Update Issue Status

Assign the issue and mark it in progress:

```bash
linear issue update ABC-123 -a self -s started
```

### 7. Create Branch and Begin

Check if already on a branch matching the issue ID:

```bash
git branch --show-current | grep -i "abc-123"
```

If not on a matching branch, create one in Linear's format:

```bash
# Format: <issue-id-lowercase>-<title-slugified>
# Example: mdc-123-add-user-auth
git checkout -b mdc-123-add-user-auth
```

Keep branch names concise—truncate long titles sensibly.

Then proceed with the agreed approach.
