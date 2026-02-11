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

Load the `code-review` skill and run the review, passing the gathered context as instructions.

**Choosing the diff source:**

- **If a PR was found** in step 1, use `gh pr diff <number>` as the diff description. This returns exactly the changes in the PR, regardless of how the base branch has moved.
- **If no PR exists**, fetch both the base branch and the target branch (`git fetch origin main <branch-name>`), then diff against it: `git diff origin/main...origin/<branch-name>`.

```
code_review(
  diff_description: "gh pr diff <number>"  // or "git diff origin/main...origin/<branch-name>" if no PR
  instructions: "Linear Issue: <issue-title-and-description>\nPR Description: <pr-body>\n\nReview with this context in mind."
)
```

### 3. Present Results

Display results using the format from `code-review`, then ask if the user wants any issues fixed.
