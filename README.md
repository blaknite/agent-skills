# Agent Skills

Custom skills for Amp that extend its capabilities for development workflows.

## Available Skills

| Skill | Description |
|-------|-------------|
| **buildkite-pipelines** | Query Buildkite CI/CD for build status, failed jobs, and logs |
| **buildkite-test-engine** | Query Buildkite Test Engine for failed tests and traces |
| **gathering-branch-context** | Gather full context for a branch (Linear issue, PR, build status) |
| **linear** | Manage Linear issues, projects, and milestones |
| **notion-pages** | Search and view Notion pages |
| **reading-pull-requests** | Find and read GitHub PRs for a branch |
| **reviewing-branch-changes** | Gather branch context then perform a comprehensive code review |
| **writing-linear-issues** | Collaboratively draft quality Linear issues through dialogue |

## Usage

Skills are automatically loaded by Amp when relevant. You can also explicitly request them:

> "Use the buildkite-pipelines skill to check the build status"

Place skills in `~/.config/agents/skills/` for Amp to discover them.
