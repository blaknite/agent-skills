---
name: using-faber
description: CLI reference for Faber. Covers every command an agent might need to dispatch, watch, inspect, and route tasks. No role logic -- just the raw interactions.
---

# Using Faber

Faber is a terminal UI for running multiple autonomous coding agents in parallel. Each task gets its own isolated git worktree and an agent to work on it. You interact with Faber through the `faber` CLI.

## Running a task

```bash
faber run "your prompt here"
```

For a specific project directory:

```bash
faber run "your prompt here" --dir <projectDir>
```

To choose a model:

```bash
faber run "your prompt here" --model smart
```

Valid model labels are `fast`, `smart`, and `deep`:

- `fast`: mechanical or well-scoped tasks where the path is obvious. Reformatting, renaming, boilerplate, simple one-file fixes.
- `smart`: the right default for most real work. Anything that requires understanding context across files, making judgment calls, or following a multi-step plan.
- `deep`: tasks where getting it wrong is expensive or the problem is genuinely hard to frame. Architecture decisions, elusive bugs, competing constraints.

`faber run` prints a task ID (e.g. `a3f2-fix-the-login-bug`). Capture it -- you'll need it for every other command.

## Watching a task

Blocks until a task is no longer running, then exits:

```bash
faber watch <taskId>
```

Exits immediately if the task is already in a terminal state (`ready`, `done`, `failed`, or `stopped`). Useful in scripts that dispatch a task and need to wait before continuing.

## Listing tasks

```bash
faber list
```

Prints a table of all tasks with their ID, status, elapsed time, and prompt. Filter by status:

```bash
faber list --status running
faber list --status ready
faber list --status failed
```

## Reading a task log

```bash
faber read <taskId>
```

Prints the agent's log with tool calls summarised as one-liners. To expand everything including file contents and diffs:

```bash
faber read <taskId> --full
```

## Inspecting a task diff

```bash
faber diff <taskId>
```

Shows what the task branch has on top of the base branch. Empty output means no changes were committed.

## Merging a task

```bash
faber merge <taskId>
```

Rebases the task branch onto the current base branch HEAD, fast-forward merges it, and removes the worktree. The task moves to `done`.

## Marking a task done

```bash
faber done <taskId>
```

Marks the task `done` without touching the worktree or branch. Use when the task was exploratory, when the agent correctly determined there was nothing to change, or when you want to keep the branch around for reference.

## Continuing a task

```bash
faber continue <taskId> "<new direction>"
```

Resumes the agent in the same session with the new prompt appended. The agent picks up where it left off with full context of what it already did.

## Deleting a task

```bash
faber delete <taskId> --yes
```

Removes the task from state, its worktree, and its branch. This is destructive and cannot be undone. The command prompts for confirmation before proceeding. Pass `--yes` to skip the prompt.

Running tasks are rejected -- stop the task before deleting it.
