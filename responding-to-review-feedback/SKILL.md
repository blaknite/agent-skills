---
name: responding-to-review-feedback
description: Collaboratively review and respond to PR code review feedback. Use when working through review comments, implementing suggestions, or responding to reviewer questions.
---

# Responding to Review Feedback

Collaborate with the user to review, triage, and respond to code review feedback from a pull request. This includes suggestions, questions, concerns, and general comments. You decide together what to act on and how to respond.

## Prerequisites

- GitHub CLI (`gh`) must be installed and authenticated
- Run `gh auth status` to verify authentication

## Starting Point

The user provides a PR reference in one of these forms:
- A PR URL (e.g., `https://github.com/owner/repo/pull/123`)
- A PR number (e.g., `#123` or `123`)
- The current branch (use `gh pr view` to find the PR)

If no PR is specified, check the current branch for an associated PR.

## Workflow

### 1. Fetch PR Details and Check Out the Branch

First, get the PR details:

```bash
gh pr view {pr_number_or_url} --json number,url,title,headRefName
```

**You MUST check out the PR branch before reading any files or making changes:**

```bash
gh pr checkout {pr_number}
```

This fetches the branch and switches to it in one step. Skipping this will cause you to read stale or unrelated code and produce incorrect responses.

Then fetch the review comments:

```bash
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments --jq '.[] | {id, path, line, body, user: .user.login, created_at, in_reply_to_id}'
```

### 2. Give a Brief Summary

Start with a quick overview so the user knows what to expect:
- Total number of comments
- Which reviewers left feedback
- Which files are affected

Example: "There are 5 comments from @alice and @bob across 3 files. Let's go through them one at a time."

### 3. Walk Through Each Comment

Present **one comment at a time** with full context. Don't reference earlier content—always include complete details when discussing each one:

```
## Comment 1 of 5

**File:** app/models/user.rb (line 42)
**From:** @alice
**Comment ID:** 12345

> Consider using `present?` instead of `!blank?` for readability.

**Current code:**
```ruby
if !name.blank?
```

How should we handle this?
```

Wait for the user's decision before moving to the next comment.

### 4. Collaborate on Decisions

For each suggestion:
- **Implement** - Apply the change immediately
- **Decline** - User provides a reason; you'll reply to the reviewer
- **Discuss** - Explore trade-offs before deciding

Don't interrogate. Have a natural conversation.

### 5. Implement Accepted Suggestions

For suggestions the user accepts:
1. Read the relevant file
2. Apply the change using `edit_file`
3. If the suggestion contains a `suggestion` code block, apply that exact code

### 6. Reply to Declined Suggestions

When declining a suggestion, discuss the reply with the user. Agree on what to say, then post it:

```bash
gh api -X POST repos/{owner}/{repo}/pulls/{pr_number}/comments/{comment_id}/replies \
  -f body="<agreed upon reply>"
```

**Important:** Only reply to top-level comments (where `in_reply_to_id` is null). You cannot reply to replies.

### 7. Summarize Actions

After processing all suggestions, summarize:
- Which suggestions were implemented
- Which suggestions were declined (with reasons)
- Any remaining suggestions to revisit

## Handling Suggested Changes

GitHub has a special syntax for suggesting code changes:

````markdown
```suggestion
replacement code here
```
````

When you see this format:
1. The suggestion block contains the exact replacement text
2. It replaces the lines referenced in the comment
3. Apply it precisely as written

## Tips

- Read surrounding code context before implementing changes
- Consider if a suggestion might break tests or other functionality
- Group related suggestions that touch the same code area
- Run relevant tests after implementing changes to verify

## Example Conversation Flow

**You:** "I found 3 review comments on this PR from @alice and @bob, touching 2 files. Let's go through them one at a time."

---

**You:**
> ## Comment 1 of 3
>
> **File:** app/models/user.rb (line 42)
> **From:** @alice
>
> > Consider using `present?` instead of `!blank?` for readability.
>
> **Current code:**
> ```ruby
> if !name.blank?
> ```
>
> Should we implement this, decline it, or discuss?

**User:** "Yes, that's reasonable."

**You:** "Implementing now... Done."

---

**You:**
> ## Comment 2 of 3
>
> **File:** app/controllers/users_controller.rb (line 28)
> **From:** @bob
>
> > You should add nil-checking here to handle the edge case.
>
> **Current code:**
> ```ruby
> user.update(params[:user])
> ```
>
> Should we implement this, decline it, or discuss?

**User:** "That's not needed—the caller already validates. Let's decline with that explanation."

**You:** "Understood. I'll reply to @bob explaining that the caller validates the input, so the nil check is redundant."
