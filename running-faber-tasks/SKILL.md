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

Use `faber dispatch`:

```bash
faber run "your prompt here"
```

Or for a specific project directory use:

```bash
faber run "your prompt here" --dir <projectDir>
```

That's it. Faber handles the rest.
