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

### 2. Prepare for Review

To prepare for the review you should:

1. **Switch to the PR branch:**
   ```bash
   git fetch origin <branch-name>
   git checkout <branch-name>
   ```

2. **Get the changed file list:**
   - If a PR was found: `gh pr diff <number> --name-only`
   - If no PR exists: `git diff origin/main...<branch-name> --name-only`

3. **Get the full diff:**
   - If a PR was found: `gh pr diff <number>`
   - If no PR exists: `git diff origin/main...<branch-name>`

### 3. Walk Through Changes

Before running the automated review, present a high-level walkthrough of the PR changes so the user understands what's been changed.

**Structure:**

1. **Context summary.** Present the context summary so it can be read along with the walkthrough

2. **Changed files.** A clickable list of all changed files formatted as `file://` links using absolute paths to the local checkout. Group files by directory or logical area if there are more than a handful.

3. **Walkthrough.** Using the diff returned by the Task:
   - Start with a one-paragraph summary of what the PR does and why, drawing on the PR description and Linear issue context gathered earlier.
   - Group changes by logical area (e.g., "schema changes", "API layer", "tests") rather than listing every file individually. Under each group, list the relevant files as clickable `file://` links with line ranges.
   - When explaining a change, show the relevant diff hunk inline so the user can see exactly what changed without having to go find it. Use fenced diff blocks (` ```diff `) for these.
   - Call out anything notable: new patterns introduced, architectural decisions, potential risk areas, or anything that needs extra scrutiny during review.

Keep the walkthrough concise but substantive. The goal is to give the user enough context to understand the changes before seeing the review results.

After presenting the walkthrough, ask: **"Ready for the code review, or do you want to dig into anything first?"**

Wait for the user to confirm before proceeding.

### 4. Perform Code Review

Load the `code-review` skill and run the review, passing the gathered context as instructions.

**Diff source:** Use the same diff from step 2.

```
code_review(
  diff_description: "gh pr diff <number>"  // or "git diff origin/main...<branch-name>" if no PR
  instructions: "Linear Issue: <issue-title-and-description>\nPR Description: <pr-body>\n\nReview with this context in mind. After presenting results, ask: 'Would you like me to fix any of these issues? Or I can write a code review if you're ready to post feedback. (e.g., \"fix issue #1\" or \"write a code review\")'"
)
```
