---
name: orchestrating-faber-tasks
description: Coordinates multiple Faber tasks in parallel toward a shared goal. Use when breaking down a larger goal into concurrent sub-tasks and driving them through to completion.
---

# Orchestrating Faber tasks

Load the `using-faber` skill for the full CLI reference. This skill covers the coordination layer: how to decompose a goal, dispatch sub-tasks in parallel, and drive the whole thing to completion.

## The loop at a glance

1. Break the goal into independent sub-tasks
2. Dispatch all of them upfront, capture each task ID
3. Watch the batch in parallel
4. Review and route each ready task (load `reviewing-faber-tasks`)
5. Dispatch follow-up tasks for anything that depends on earlier results
6. Repeat until all tasks are merged or done and nothing is outstanding

## Step 1: Break the goal into sub-tasks

Before dispatching anything, identify which parts of the goal are independent and which must sequence. Independent work can run in parallel from the start. Work that depends on a prior result has to wait.

A task is independent when:
- It touches different files or systems than the others
- It doesn't need to know what another task decided or produced
- It can be reviewed and merged without coordination

A task must sequence when:
- It builds on code that doesn't exist yet
- It needs to know the API or schema that a prior task will define
- Merging it before the other task would break the build

If in doubt, lean toward sequencing. Two tasks that conflict on the same file are harder to recover from than a slightly longer wall clock time.

## Step 2: Write prompts and dispatch the batch

Write prompts following the guidance in `running-faber-tasks`. Each sub-task runs in its own isolated worktree, so the agent starts cold -- include everything it needs in the prompt.

Also choose the right model for each task -- see `using-faber` for guidance on `fast`, `smart`, and `deep`.

Run all independent tasks upfront and capture each task ID. Don't dispatch a dependent task until the task it depends on has been merged.

## Step 3: Wait for the batch

Watch all running tasks in parallel using `faber watch` in the background for each task ID. If you can't run them in the background, run them sequentially -- each one exits as soon as its task is ready, so the order doesn't matter.

## Step 4: Review and route each ready task

Load `reviewing-faber-tasks` and run through the decision loop for each ready task before dispatching the next round.

Don't wait for all tasks to be ready before acting on the ones that are. Review what's done, merge what's clean, continue what needs fixing, and move to the next round with whatever is left.

## Step 5: Dispatch follow-up tasks

After dependent tasks are merged, dispatch the work that was waiting on them. Keep track of what's been merged and what's still in flight:

```
Round 1 (parallel):
  a1b2-add-export-validation    -> merged
  c3d4-add-import-validation    -> merged (after continue)

Round 2 (depends on round 1):
  g7h8-update-api-docs          -> watching...
```

## Step 6: Recognise when you're done

The goal is complete when all tasks are merged or done, nothing is still running or waiting, and nothing from the original goal is unaddressed. Use `faber list` to confirm.

## Handling failures and stuck tasks

If a task fails the same way twice, the prompt is probably wrong. Rewrite it with more context, a different scope, or a more constrained goal before retrying.

If a task keeps failing and the work can be done a different way, delete it and dispatch a replacement with a different framing.

## Example: full orchestration

```bash
# Round 1: independent tasks, dispatch in parallel
faber run "Add rate limiting middleware. Limit unauthenticated requests to 60/min. Base branch: main"
# Dispatching task: aa11-rate-limiting-middleware

faber run "Add Redis client config. The rate limiter will use Redis as the store. Base branch: main"
# Dispatching task: bb22-redis-client-config

# Wait for both in parallel
faber watch aa11-rate-limiting-middleware &
faber watch bb22-redis-client-config &
wait

# Review and route each one (see reviewing-faber-tasks)
# aa11 looks good -- merge it
faber merge aa11-rate-limiting-middleware

# bb22 missed something -- continue it
faber continue bb22-redis-client-config "Add connection pooling config, the rate limiter needs it."
faber watch bb22-redis-client-config
faber merge bb22-redis-client-config

# Round 2: depends on both being merged
faber run "Wire the rate limiting middleware to the Redis client. Integration tests must pass. Base branch: main"
# Dispatching task: cc33-wire-rate-limiter-to-redis

faber watch cc33-wire-rate-limiter-to-redis
faber merge cc33-wire-rate-limiter-to-redis

# Confirm nothing is left outstanding
faber list
```
