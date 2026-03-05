---
name: reading-buildsworth-logs
description: Downloads and reads pi session logs from Buildsworth builds on the buildkite/buildsworth pipeline. Use when asked to inspect what an agent did, answer questions about a build's findings, or read a pi session artifact.
---

# Reading Buildsworth logs

Buildsworth builds produce pi session artifacts: `.jsonl` files written by the pi agent that record everything it did. This skill covers how to get them and how to read them without wrecking your context.

## Step 1: Download the artifact

Taks a sub-agent with downloading the log. Never download the log in your own context.

Use the `using-buildkite` skill for the full CLI reference. The short version:

```bash
# Find the artifact ID
bk artifacts list <build-number> -p buildkite/buildsworth -o json

# Create ./tmp if it doesn't exist, then download into it. Do not pass -p to bk
mkdir -p ./tmp && cd ./tmp && bk artifacts download <artifact-id>
```

The downloaded file will be a `.jsonl` at a path like:
`./tmp/artifact-<id>/2026-03-05T00-42-16-011Z_<uuid>.jsonl`

The artifact is on the "Review pull request" job. If there are multiple artifacts, look for the one with a path matching `root/.pi/agent/sessions/`.

## Step 2: Always delegate reading to a sub-agent

Never load the `.jsonl` into your own context. It can be hundreds of kilobytes. Spin up a sub-agent with the file path and a specific question; let it pay the context cost and return only the answer.

Example prompt to a sub-agent:

> Read the pi session log at ./tmp/artifact-019cbb75.../2026-03-05T...jsonl. Did the agent find any security issues, and if so what were they?

Keep the question narrow. "What did the agent do?" produces a wall of text. "Were there any failing checks?" produces a sentence.

## Step 3: Ask one question per sub-agent

The log is a transcript. One focused question per sub-agent call is more reliable than one open-ended one. Spin up multiple sub-agents in parallel if you have multiple questions.

Good questions:

- What was the agent's final verdict?
- Did it find any security issues?
- Were there any tool call errors?
- What files did it look at?
- Did it leave any comments on the PR?

Avoid "summarise everything" unless the user genuinely asked for a full summary. Even then, a focused set of questions produces a better result than one open-ended one.
