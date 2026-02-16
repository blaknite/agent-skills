---
name: specifying-behaviour
description: Write structured natural language behaviour specifications for features or changes. Use when describing acceptance criteria, defining expected behaviour, or specifying how something should work.
---

# Specifying Behaviour

A behaviour specification is a short, structured natural language description of how something should work. It sits between a formal test and a vague user story: precise enough to be unambiguous, readable enough that anyone can follow it.

## Structure

1. **Lead with the core behaviour** in a single declarative sentence.
2. **Follow with "when" clauses** for edge cases and alternate paths.
3. **Add short declarative statements** for constraints, exemptions, or side effects.

Each statement should describe one concern. Say *what* happens, not *how* it's implemented.

## Examples

A specification for pipeline triggers:

> A pipeline runs when a commit is pushed to a branch matching its trigger pattern. When a pipeline is already running for that branch, cancel the in-progress run. Draft pull requests do not trigger pipelines unless explicitly configured.

A specification for deploy gates:

> Production deploys require approval from at least one member of the ops team. When no approval is given within 4 hours, the deploy is cancelled. Hotfix branches skip the approval requirement.

## Guidelines

- Use concrete values (4 hours, 3 retries, 500MB) over vague language ("should handle retries gracefully").
- Name the actors and resources involved ("pipeline", "ops team", "hotfix branches") rather than using generic terms like "the system".
- Keep specifications short. If you need more than five or six statements, you're probably describing multiple behaviours and should split them up.
