---
name: running-faber-tasks
description: Dispatches a single Faber task. Use when handing off one piece of work to an agent. Covers writing a good prompt and firing off the task.
---

# Running a Faber task

Load the `using-faber` skill for the full CLI reference. This skill covers what makes a good single task prompt and when to use this approach over full orchestration.

## When to run a single task

Use this when the work is self-contained -- one goal, one agent, no dependency on other tasks running in parallel. If you need to coordinate multiple tasks toward a larger goal, load `orchestrating-faber-tasks` instead.

## Writing a good prompt

A good prompt gives the agent enough to work independently. Three things matter:

**What to do.** Be specific about the goal. "Add CSV export to the metrics endpoint" is better than "add export support".

**Why it matters or what to watch out for.** If there's relevant context the agent can't discover from the code, include it. Known pitfalls, related work, constraints.

**What done looks like.** Describe the expected behaviour.

Always end the prompt with `Base branch: <branch>` so the agent knows where its worktree was cut from.

Example:

```
Fix the crash when users with no avatar visit their profile.

User#avatar_url returns nil when no avatar is set, which breaks the
profile template. Add a fallback to a default avatar URL.

Visiting a profile without an avatar should show the default image
instead of crashing.

Base branch: main
```

## Next steps

Once the task is running, use `faber watch` to block until it's ready, then load `reviewing-faber-tasks` to assess what the agent produced and route it accordingly.

## Example

```bash
faber run "Fix the crash when users with no avatar visit their profile.

User#avatar_url returns nil when no avatar is set, which breaks the
profile template. Add a fallback to a default avatar URL.

Visiting a profile without an avatar should show the default image
instead of crashing.

Base branch: main"
# Dispatching task: a3f2-fix-avatar-crash

faber watch a3f2-fix-avatar-crash
# Task a3f2-fix-avatar-crash (status: ready)

# Now load reviewing-faber-tasks to assess and route the result
```
