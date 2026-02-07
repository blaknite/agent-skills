---
name: contextual-code-review
description: "Code review with full context. Gathers Linear issue, PR details, and build status before reviewing. Use when asked to review a PR, review branch changes, or do a code review with context."
---

# Contextual Code Review

Perform a code review with full context by combining the `gathering-branch-context` and `code-review` skills.

## Workflow

### 1. Gather Context

Load and execute the `gathering-branch-context` skill to collect:
- Linear issue details (title, description, acceptance criteria)
- Pull request details (description, status, reviews)
- Build status (passed/failed, failed jobs)

### 2. Perform Code Review

Load the `code-review` skill and run the review, passing the gathered context as instructions:

```
code_review(
  diff_description: "Changes on branch <branch-name> compared to origin/main",
  instructions: "Linear Issue: <issue-title-and-description>\nPR Description: <pr-body>\n\nReview with this context in mind."
)
```

### 3. Present Results

Display results using the format from `code-review`, then ask if the user wants any issues fixed.
