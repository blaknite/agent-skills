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

### 2. Walk Through Changes

Before running the automated review, present a high-level walkthrough of the PR changes so the user understands what's been changed.

**Getting the diff:**

- **If a PR was found**, use `gh pr diff <number>`.
- **If no PR exists**, fetch and diff: `git fetch origin main <branch-name>` then `git diff origin/main...origin/<branch-name>`.

**Walkthrough format:**

1. Start with a one-paragraph summary of what the PR does overall.
2. Walk through the key changes file-by-file or by logical grouping, explaining what each change does and why it matters. Link to specific files and line ranges.
3. Call out anything notable: new patterns introduced, architectural decisions, potential risk areas, or anything that needs extra scrutiny during review.

Keep the walkthrough concise but substantive. The goal is to give the user enough context to understand the changes before seeing the review results.

After presenting the walkthrough, ask: **"Ready for the code review, or do you want to dig into anything first?"**

Wait for the user to confirm before proceeding.

### 3. Perform Code Review

Load the `code-review` skill and run the review, passing the gathered context as instructions.

**Diff source:** Use the same diff from step 2.

```
code_review(
  diff_description: "gh pr diff <number>"  // or "git diff origin/main...origin/<branch-name>" if no PR
  instructions: "Linear Issue: <issue-title-and-description>\nPR Description: <pr-body>\n\nReview with this context in mind."
)
```

### 4. Present Results

Display results using the format from `code-review`, then ask if the user wants any issues fixed.
