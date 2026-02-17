---
name: performing-technical-discovery
description: "Investigates how existing systems relate to a proposed change. Use when exploring a problem before committing to build, scoping work, or producing a discovery document."
---

# Technical Discovery

Produce a discovery document that maps the technical landscape relevant to a proposed change. The document should give an engineer unfamiliar with the problem enough context to get up and running quickly.

## When to Use

- Early in the change process (pitch, PRD, or pre-planning)
- When scoping work for a new feature or change
- When someone needs to understand how existing systems relate to a problem
- Before writing Linear issues or implementation plans

## Process

1. **Clarify the problem** — Ask the user to describe what they're considering. Understand the intent, not just the surface request.

2. **Investigate the codebase** — Use search tools extensively to find:
   - Relevant models, controllers, services
   - Related features that solve similar problems
   - Data structures and relationships
   - Integration points and dependencies

3. **Trace the flow** — Use the `walkthrough` skill if needed to understand how existing systems work together.

4. **Document findings** — Produce a discovery document (see format below).

5. **Identify open questions** — Flag things that couldn't be determined or need human input.

## Discovery Document Format

```markdown
# Discovery: [Problem/Proposal Name]

## Context
Brief description of what's being considered and why this investigation was needed.
Keep to 2-3 sentences.

## Relevant Systems
For each relevant system, describe:
- What it does
- How it relates to the problem
- Link to key files

Keep descriptions concise—enough to orient, not to teach.

## Data & Models
Relevant data structures, relationships, and constraints.
Include a Mermaid ERD if relationships are non-trivial.

## Integration Points
Where a solution would need to connect, hook into, or modify existing code.
Be specific—name files, methods, or patterns.

## Constraints & Considerations
Technical limitations, performance concerns, edge cases, or gotchas discovered.
Only include what's relevant to decision-making.

## Open Questions
Things that couldn't be determined or require human input.
```

## Guidelines

### Be Comprehensive Yet Concise
- Include enough detail that an unfamiliar engineer can orient quickly
- Exclude tangential information that doesn't inform the problem
- Link to files rather than copying large code blocks
- Use diagrams when they communicate faster than prose

### Stay Neutral
- Present findings, not recommendations
- Document what exists and how it relates to the problem
- Leave the "should we?" decision to the reader

### Focus on the Problem
- Every section should connect back to the proposed change
- Skip systems that aren't relevant, even if interesting
- If a system is tangentially related, mention it briefly and move on

### Surface Unknowns
- Be explicit about what you couldn't determine
- Distinguish between "this doesn't exist" and "I couldn't find it"
- Flag areas that would benefit from human expertise
