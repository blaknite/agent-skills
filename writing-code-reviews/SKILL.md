---
name: writing-code-reviews
description: "Collaboratively draft code review comments for a GitHub PR. Refines comments with the user until they're happy with the wording. Use when asked to write a code review or draft review comments."
---

# Writing Code Reviews

Collaboratively refine code review comments on a GitHub pull request. This skill does NOT perform the review itself — it takes the results of an already-completed code review (from the `code-review` or `reviewing-code-with-context` skill) and handles collaborative refinement.

Load skills: giving-kind-feedback

## Prerequisites

- GitHub CLI (`gh`) must be installed and authenticated
- A code review has already been performed and issues are available in context
- Load the `giving-kind-feedback` skill before drafting any comments. All review comments must follow its principles.

## Starting Point

This skill is invoked after a code review has been completed. The review issues should already be present in the conversation context (e.g., from the `code-review` skill's table output).

The user may provide a PR reference as:
- A PR URL (e.g., `https://github.com/owner/repo/pull/123`)
- A PR number (e.g., `#123` or `123`)
- The current branch (use `gh pr view` to find the PR)

If no PR is specified, check the current branch for an associated PR.

## Workflow

### 1. Identify the PR

Determine the repository owner/name and PR number:

```bash
# If on the branch
gh pr view --json number,url,headRefName

# If given a number
gh pr view <number> --repo <owner>/<repo> --json number,url,headRefName
```

### 2. Select Issues

Ask the user which review issues to include as PR comments:

**"Which issues would you like to include in the review? You can refine wording, drop issues, or add context. (e.g., 'include 1, 3, 5' or 'all' or 'drop 2 and 4')"**

### 3. Collaborate on Comments

Load the `giving-kind-feedback` skill now if not already loaded. Apply its principles when drafting every comment: own the confusion, offer a path forward, and advocate for the next reader rather than personal preference.

This is a collaborative step. The user may:
- Select which issues to include or exclude
- Refine the wording of individual comments
- Add additional context or soften/strengthen tone

For each selected issue, draft the comment body. The code-review tool's "why" and "fix" fields are diagnostic notes for your understanding, not comment templates. Look at each issue in the context of the whole PR and frame your comments accordingly.

Comment where the fix belongs, not where the symptom appears. The reader should be able to understand the issue with minimal effort.

Every comment must start with a short intent label ("Nit:", "Minor:", "Thought:", "Important:", "Blocking:") that tells the author how much weight to give it. Avoid disclaimer sentences. The label handles severity signalling, the tone handles the rest.

When a comment has an exact code fix for specific lines, use a ` ```suggestion ` fence instead of a plain code block. Only do this when you can provide the complete replacement text for the lines covered by the comment's `line` / `start_line` range. Use a regular code block for conceptual or ambiguous fixes.

Present the full draft of every comment exactly as it would appear on GitHub. The user is authoring this review under their name, so they must see the complete wording before approving submission. Do not truncate, abbreviate, or summarize comment bodies.

When presenting the draft, suggestion blocks are indistinguishable from regular code blocks in terminal output. To make them reviewable, surround suggestion fences with **[suggestion]** / **[/suggestion]** wrapper tags and surround regular code fences with **[code]** / **[/code]** wrapper tags. These wrappers are only for the draft preview and must not be included in any later submission payload.

````
## Review Draft

### 1. `src/foo.ts:42`

<comment text>

**[suggestion]**
```suggestion
  replacement code here
```
**[/suggestion]**

### 2. `src/bar.ts:15`

<comment text>

**[code]**
```
  conceptual example here
```
**[/code]**

---

Any changes?
````

If the user requests wording changes, update and present only the affected comment(s), then check again.
