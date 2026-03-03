---
name: running-faber-tasks
description: Runs prompts in Faber tasks via the CLI. Use when creating autonomous tasks or submitting work to Faber.
---

# Running Faber Tasks

## What is Faber?

Faber is a terminal UI for running multiple autonomous coding agents in parallel. You give it a prompt, and it creates an isolated git worktree, spins up an agent to work on the task, and keeps the work organized while you dispatch more tasks.

## Writing a task prompt

A good prompt gives the agent enough to work independently. Three things matter:

**What to do.** Be specific about the goal. "Add CSV export to the metrics endpoint" is better than "add export support".

**Why it matters or what to watch out for.** If there's relevant context the agent can't discover from the code, include it. Known pitfalls, related work, constraints.

**What done looks like.** Describe the expected behaviour.

Example:

```
Fix the crash when users with no avatar visit their profile.

User#avatar_url returns nil when no avatar is set, which breaks the
profile template. Add a fallback to a default avatar URL.

Visiting a profile without an avatar should show the default image
instead of crashing.
```

## Running a task

Use `faber run`:

```bash
faber run "your prompt here"
```

Or for a specific project directory use:

```bash
faber run "your prompt here" --dir <projectDir>
```

You can also pass `--model` to choose the model for the task. The default is `smart`:

```bash
faber run "your prompt here" --model smart
```

That's it. Faber handles the rest.

## Choosing a model

Valid model labels are `fast`, `smart`, and `deep`. Use this heuristic to pick:

- `fast`: mechanical or well-scoped tasks where the path is obvious. Reformatting, renaming, boilerplate generation, simple one-file fixes, tasks that are essentially find-and-replace at scale.
- `smart`: the right default for most real work. Anything that requires understanding context across files, making reasonable judgment calls, or following a multi-step plan. If you're unsure, use this.
- `deep`: tasks where getting it wrong is expensive or the problem itself is genuinely hard to frame. Architecture decisions, debugging an elusive root cause, tasks with competing constraints that need careful reasoning, or anything where you'd want a second pair of eyes before committing.

## Watching a task

After dispatching a task headlessly, you can wait for it to finish using `faber watch`:

```bash
faber watch <taskId>
```

The task ID is the slug printed by `faber run` (e.g. `a3f2-fix-the-login-bug`). `faber watch` blocks until the task is no longer running, then exits. This is useful in scripts that dispatch a task and need to wait for the result before continuing.

If the task is already finished when you run `faber watch`, it exits immediately.

Example:

```bash
faber run "Fix the login bug"
# Dispatching task: a3f2-fix-the-login-bug

faber watch a3f2-fix-the-login-bug
# Watching task a3f2-fix-the-login-bug (status: running)
# Task a3f2-fix-the-login-bug finished (status: ready)
```
