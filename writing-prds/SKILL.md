---
name: writing-prds
description: Collaboratively draft concise product requirements documents through rubber duck dialogue. Use when writing PRDs, documenting feature requirements, or refining product specs.
---

# Writing PRDs

Collaborate with the user to craft clear, concise PRDs through iterative refinement.

Load skills: specifying-behaviour

## Starting Point

The user arrives with context about a customer problem or feature pitch, often with a rough solution in mind.

### Gather Context First

Before starting the rubber duck session, ask:

"Before we dive in, is there anything I should read to get context?"

Offer to read from:
- **Notion** — product specs, meeting notes, customer feedback
- **Linear** — related issues, project context
- **GitHub** — PRs, discussions, code
- **Codebase** — relevant files, existing implementations
- **Slack** — conversations, threads, decisions
- **Zoom** — meeting recordings, transcripts
- **URLs** — external docs, references

Also check the project's AGENTS.md for product-specific terminology, architecture, and customer context.

Once context is gathered, ask: "What's the problem or feature you want to document?"

## Rubber Duck Process

Act as a thinking partner. Your job is to help the user clarify their thinking, not transcribe it.

### Core Questions to Explore

Extract these through natural conversation, not as a checklist:

1. **The Problem** — What pain or opportunity exists? What's broken, missing, or frustrating?
2. **The Customer** — Who experiences this? What outcome do they want?
3. **The Solution** — What's the proposed approach? Why this over alternatives?
4. **Success** — How do we know it worked? What metrics matter?
5. **Scope** — What's in? What's explicitly out?
6. **Requirements** — Functional needs, constraints, edge cases?
7. **Unknowns** — What risks or open questions remain?

### How to Collaborate

- **Challenge assumptions** — Don't accept vague statements; push for specifics
- **Explore edge cases** — What happens when things go wrong?
- **Question scope** — Is this too big? Too small? What can be cut?
- **Clarify ideas** — Reflect back what you're hearing to sharpen thinking
- **Distill language** — Propose concise descriptions of complex ideas

Don't interrogate. Have a conversation. Don't draft too early — thoroughly explore the problem space first.

## Drafting the PRD

Only propose a draft when the problem space is well understood. The PRD should be:

- **Concise** — No more than 2 pages. Respect the reader's time.
- **Clear** — Anyone picking this up should understand the why, not just the what.
- **Actionable** — Clear enough for prioritization and execution.

Use the `specifying-behaviour` skill to write precise behaviour specs

### PRD Structure

```markdown
# [Feature/Problem Name]

## Problem Statement
What pain or opportunity exists. Current state vs desired state.

## Customer
Who experiences this problem. What outcome they need.

## Proposed Solution
High-level approach. Why this solution over alternatives.

## Goals & Success Metrics
What success looks like. How we'll measure it.

## Scope
### In Scope
- What's included

### Out of Scope
- What's explicitly excluded (and why)

## Requirements
### Functional
- What the solution must do

### Non-Functional
- Performance, security, scalability constraints

### Constraints
- Technical, timeline, or resource limitations

## Open Questions & Risks
- Unknowns to resolve before or during implementation
```

## Finalizing

Present the draft and ask: "Does this capture what you had in mind? Any adjustments?"

Once confirmed, save the PRD as a markdown file for the user to use elsewhere.
