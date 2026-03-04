---
name: planning-faber-orchestration
description: Synthesises a PRD, technical discovery, and codebase investigation into an agent-ready PLAN.md. Use when you have a feature or change to implement and want to plan it before dispatching Faber tasks.
---

# Planning Faber orchestration

Produce a PLAN.md that an orchestrator can act on directly.

## What this skill does

Takes whatever context exists -- a PRD, a discovery doc, a Linear issue, a rough idea -- and synthesises it into a PLAN.md written at agent level: specific files, function signatures, data shapes, and sequencing notes. Not a design document for humans. Instructions an agent can execute cold.

## Step 1: Gather context

If the user hasn't described what they're building, ask: "What are we building?"

Work with whatever context they've provided -- a PRD, a discovery doc, a Linear issue, file references, URLs. Don't ask for things that are already there. If something critical is missing, ask specifically for it rather than asking open-ended questions.

## Step 2: Investigate the codebase

Whether or not a discovery doc exists, verify the key details yourself:
- Find the actual files the implementation will touch
- Check how related features are implemented (follow the existing pattern)
- Identify integration points: where new code hooks into old code
- Note data shapes, type signatures, and naming conventions already in use

Don't draft until you can name specific files and functions. Vague plans produce vague agents.

## Step 3: Draft the PLAN.md

### Structure

```markdown
# <Feature name>

## Summary
Why this exists. 1-3 sentences. What problem it solves.

## Requirements
User-visible or API-visible behaviour, precise enough for an agent to verify its own work.
Include exact UI text, data formats, edge case handling.

## Context
Existing systems, data flows, and patterns the implementation builds on.
Name specific files. Include relevant code shapes (types, function signatures) already in the codebase.
Explain constraints or gotchas discovered during investigation.

## Implementation
Per-component breakdown. For each piece:
- Which file(s) it touches
- What changes or gets added (new types, new functions, modified behaviour)
- Exact signatures where they matter
- What done looks like

## Implementation order
Numbered list of sequenced steps when ordering matters.
Identify which steps are independent (can run in parallel) and which must follow earlier steps.
```

### What makes a good plan

- **Specific enough to execute cold.** An agent starting in an isolated worktree with no prior context should be able to read this plan and implement without asking questions.
- **Grounded in real files.** Every component in the implementation section should reference an actual file path.
- **Honest about sequencing.** If step B needs the type that step A adds, say so. The orchestrator uses this to build the task graph.
- **No padding.** Skip sections that don't apply. A short, precise plan beats a thorough one that buries the signal.

## Step 4: Review with the user

Present the draft and ask if it captures what they had in mind. Adjust until they're happy.

Then ask where to save it. A good convention is `.plans/<feature-slug>/PLAN.md`.
