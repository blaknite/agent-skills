# Agent Skills

Custom skills for Amp that extend its capabilities for development workflows.

## Available Skills

| Skill | Description |
|-------|-------------|
| **using-buildkite** | Buildkite CLI and Test Engine API reference |
| **debugging-failed-builds** | Debug failed Buildkite builds by finding failed jobs and reading logs |
| **debugging-failed-tests** | Debug failed tests using Buildkite Test Engine |
| **reviewing-code-with-context** | Code review with full context (Linear issue, PR details, build status) |
| **gathering-context** | Gather full context for a branch (Linear issue, PR, build status) |
| **using-linear** | Manage Linear issues, projects, and milestones |
| **reading-notion** | Search and view Notion pages |
| **reading-pull-requests** | Find and read GitHub PRs for a branch |
| **starting-linear-issue** | Start work on a Linear issue by gathering context and creating a branch |
| **submitting-code-reviews** | Submit finalized code review comments to a GitHub PR via the batch review API |
| **submitting-pull-requests** | Create and submit PRs with well-structured descriptions |
| **giving-kind-feedback** | Kind engineering principles for giving feedback |
| **performing-technical-discovery** | Investigate how existing systems relate to a proposed change |
| **reading-slack** | Read Slack channels, threads, and messages |
| **responding-to-review-feedback** | Review and respond to PR code review feedback |
| **specifying-behaviour** | Write structured natural language behaviour specifications |
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

If you already have Amp and its dependencies installed and just want to install the skills:

```bash
curl -fsSL https://raw.githubusercontent.com/blaknite/agent-skills/main/install.sh | bash -s -- --skip-deps
```

## Usage

Skills are automatically loaded by Amp when relevant:

> "Let's get started on BK-123"

> "Watch the latest build and debug and relevant failures"

You can also explicitly request them:

> "Use the using-buildkite skill to check the build status"
