---
name: writing-linear-project-updates
description: Collaboratively draft Linear project updates through dialogue. Use when writing project updates, status reports, or progress summaries for Linear projects.
---

# Writing Linear Project Updates

Collaborate with the user to craft clear, informative project updates through iterative refinement.

## Starting Point

The user provides a Linear project URL or project identifier. Load the `linear` skill and fetch the project details including:
- Project name, description, and content (PRD/scope)
- Current issues and their states
- Recent project updates (for tone/format reference)

For issues that are "In Review", use the `reading-pull-requests` skill to fetch PR details. This provides context on what's actively being reviewed without requiring the user to explain it manually.

## Rubber Duck Process

Act as a thinking partner. Your job is to help the user clarify what they want to communicate through helpful questions.

### Core Questions to Explore

Ask these through natural conversation, not as a checklist:

1. **Status** - Is the project on track, at risk, or off track?
2. **Progress** - What shipped or moved forward since the last update?
3. **Blockers** - Are there any blockers, risks, or dependencies to call out?
4. **Timeline** - What's the outlook? When do key milestones ship?

### How to Collaborate

- Start by reviewing the project state and issues
- Ask targeted questions about what's changed
- Propose a draft once you have enough context
- Iterate on tone, structure, and content based on feedback
- Keep it conversational, not an interrogation

## Drafting the Update

When enough context exists, propose a draft update. Structure:

**Header**: Health status emoji + summary line with milestone/timeline

**What's happening**: Current work in progress, what's in review, what shipped

**Next steps**: What needs to happen to complete the current milestone

**Blockers/Risks** (if any): Call out anything that could derail progress

**Related work** (optional): Tangential items that readers may care about

### Health Status

- 🟢 **On Track** - Progressing as planned
- 🟡 **At Risk** - Potential issues that need attention
- 🔴 **Off Track** - Blocked or significantly delayed

### Writing Principles

- **Concise** - Respect the reader's time. No essays.
- **Informative** - What changed? What's next? Any concerns?
- **Honest** - Don't hide problems. Surface risks early.
- **Actionable** - Clear enough that readers know if they need to act.

## Finalizing

Present the draft and ask: "Does this capture the current state? Ready to post?"

Once confirmed, post using the Linear GraphQL API:

```bash
LINEAR_TOKEN=$(linear auth token)

# First get the project UUID from the slug
PROJECT_UUID=$(curl -s -X POST https://api.linear.app/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: $LINEAR_TOKEN" \
  -d '{"query": "{ project(id: \"PROJECT_SLUG\") { id } }"}' | jq -r '.data.project.id')

# Then create the update
curl -s -X POST https://api.linear.app/graphql \
  -H "Content-Type: application/json" \
  -H "Authorization: $LINEAR_TOKEN" \
  -d '{
    "query": "mutation($input: ProjectUpdateCreateInput!) { projectUpdateCreate(input: $input) { success projectUpdate { url } } }",
    "variables": {
      "input": {
        "projectId": "PROJECT_UUID",
        "health": "onTrack|atRisk|offTrack",
        "body": "UPDATE_BODY_MARKDOWN"
      }
    }
  }'
```

Replace:
- `PROJECT_SLUG` with the slug from the URL (e.g., `a74ff3a2c8d4`)
- `PROJECT_UUID` with the fetched UUID
- `health` with one of: `onTrack`, `atRisk`, `offTrack`
- `UPDATE_BODY_MARKDOWN` with the update content (escape quotes and newlines)
