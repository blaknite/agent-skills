---
name: writing-linear-issues
description: Collaboratively draft quality Linear issues through rubber duck dialogue. Use when creating issues, writing tickets, or refining problem statements for Linear.
---

# Writing Linear Issues

Collaborate with the user to craft clear, focused Linear issues through iterative refinement.

## Starting Point

The user provides initial context in one of these forms:
- A description of a problem or idea
- Pasted content (logs, errors, discussions)
- A request to read something (file, URL, thread)

If context is unclear or missing, ask: "What's on your mind? Describe the problem or idea you want to capture."

## Rubber Duck Process

Act as a thinking partner. Your job is to help the user clarify their thinking through helpful questions and suggestions.

### Core Questions to Explore

Extract these through natural conversation, not as a checklist:

1. **The Problem** - What's broken, missing, or frustrating? What's the current state vs desired state?
2. **The Customer** - Who experiences this problem? What outcome do they want? (Be explicit - this context is critical)
3. **The Intent** - What does success look like? What should be true when this is done?
4. **Requirements** - What constraints, acceptance criteria, or technical considerations matter?

### How to Collaborate

- Ask clarifying questions based on what's missing or unclear
- Offer suggestions to sharpen language or focus
- Challenge vague statements - push for specifics
- Propose alternatives when something feels off
- Keep iterating until the user is satisfied

Don't interrogate. Have a conversation.

## Drafting the Issue

When enough context exists, propose a draft issue. Structure should match intent:

**Bug**: Problem → Impact → Expected behavior → Steps to reproduce (if known)

**Feature**: Customer need → Desired outcome → Requirements → Out of scope (if relevant)

**Tech Debt**: Current state → Why it's a problem → Proposed improvement → Benefits

**Task**: Context → What needs to be done → Acceptance criteria

### Writing Principles

- **Concise** - No essays. Respect the reader's time.
- **Clear** - Anyone picking this up should understand the why, not just the what.
- **Customer-focused** - The outcome matters more than the implementation.
- **Actionable** - Clear enough to start work without a follow-up meeting.

## Finalizing

Present the draft and ask: "Does this capture what you had in mind? Ready to create the issue?"

Once confirmed, use the `linear` skill to create the issue in Linear.
