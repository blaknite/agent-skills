# Agent Skills

Custom skills for Amp that extend its capabilities for development workflows.

## Available Skills

| Skill | Description |
|-------|-------------|
| **buildkite-pipelines** | Query Buildkite CI/CD for build status, failed jobs, and logs |
| **buildkite-test-engine** | Query Buildkite Test Engine for failed tests and traces |
| **contextual-code-review** | Code review with full context (Linear issue, PR details, build status) |
| **gathering-branch-context** | Gather full context for a branch (Linear issue, PR, build status) |
| **linear** | Manage Linear issues, projects, and milestones |
| **notion-pages** | Search and view Notion pages |
| **reading-pull-requests** | Find and read GitHub PRs for a branch |
| **starting-linear-issue** | Start work on a Linear issue by gathering context and creating a branch |
| **submitting-pull-requests** | Create and submit PRs with well-structured descriptions |
| **technical-discovery** | Investigate how existing systems relate to a proposed change |
| **writing-linear-issues** | Collaboratively draft quality Linear issues through dialogue |
| **writing-linear-project-updates** | Collaboratively draft Linear project updates through dialogue |
| **writing-prds** | Collaboratively draft product requirements documents through dialogue |

## Installation

```bash
curl -fsSL https://raw.githubusercontent.com/blaknite/agent-skills/main/install.sh | bash
```

This will:
- Install [Amp](https://ampcode.com) if not already installed
- Check for skill dependencies (`gh`, `bk`, `linear`, `jq`, `ruby`, `go`, `notion-cli`)
- Download and install skills to `~/.config/agents/skills/`

If any skills already exist, you'll be prompted to overwrite, skip, diff, or backup.

## Usage

Skills are automatically loaded by Amp when relevant:

> "Let's get started on BK-123"

> "Watch the latest build and debug and relevant failures"

You can also explicitly request them:

> "Use the buildkite-pipelines skill to check the build status"
