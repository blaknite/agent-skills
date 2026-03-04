---
name: working-in-faber
description: Context and commit conventions for agents running inside a Faber worktree. Use when working inside a .worktrees/ directory or when the task was dispatched by Faber.
---

# Working in Faber

You are running inside a Faber worktree. Faber is a TUI that orchestrates autonomous coding agents in parallel. Each task gets its own isolated git worktree at `.worktrees/<task-slug>` with its own branch. That branch is yours.

## What this means for you

- Your working directory is a git worktree, not the main checkout.
- You are on a dedicated branch named after your task slug.
- Other agents may be running in sibling worktrees on their own branches at the same time.
- When you finish, your work needs to be committed to your branch so it can be reviewed and merged.

## Inspecting changes relative to the base branch

The initial prompt Faber sends you includes a "Base branch" label. That's the branch your task branch was cut from. Because worktrees share the same git object store, that branch is available by name without any fetch.

To see what your task branch has added on top of it:

```
git diff <baseBranch>...HEAD
```

To list the commits on your branch that aren't on the base branch:

```
git log <baseBranch>..HEAD --oneline
```

If you want to see what conflicts would exist if your branch were merged into the base branch, you can do a dry run without touching the working tree:

```
git merge-tree $(git merge-base HEAD <baseBranch>) HEAD <baseBranch>
```

Conflict markers in that output mean there are overlapping edits. You can use this to decide whether to reorganize your commits, but don't perform the merge yourself. Faber handles merging. Your job is to commit your work cleanly on your own branch and stop there.

## Reading other tasks

When your prompt contains a reference like `@123456-some-slug`, that's a faber task reference. The pattern is a bare `@` followed by a task slug: a short hex prefix, a hyphen, then a descriptive name. It points to another faber task by its ID. Load the `using-faber` skill to learn how to read it.

Instead of loading a task's entire log into your context, delegate to a sub-agent. Ask the sub-agent to read the log and answer your specific questions. The sub-agent should return only the information you need, not a full transcript.

## Handling tool failures

If a tool call fails or permission is rejected, you must continue your work. You MUST NOT stop. Retry the call or try another option.

## When you're done

If you wrote any code, commit it before finishing. Follow these rules:

**Commit in logical units.** Don't shove everything into one giant commit. Group related changes together. A bug fix and its test belong together. A refactor that touches many files is one commit. Two unrelated features are two commits.

**Write commit messages that explain the why.** The diff shows what changed. The message should explain why. "Fix crash when user has no avatar" is better than "update user.rb". If there's useful context, include it.

**Commit message format:**
- Subject line: 72 characters max, imperative mood ("Add", "Fix", "Remove", not "Added", "Fixed", "Removed")
- Leave a blank line before the body if you include one
- Body: explain the reasoning, not a summary of the diff

**Stage carefully.** Don't commit unrelated changes together. If you modified a file for two different reasons, think about whether they should be separate commits.

**Do not push.** Your job ends at the commit. Faber and the user handle the rest.

**If there's nothing to commit, that's fine.** If the task was purely exploratory or the work is already committed, say so clearly and stop.

## Example wrap-up

After finishing your work, tell the user:
- What you did and why
- How many commits you made and what they cover
- Whether tests pass (if the project has tests, run them)
