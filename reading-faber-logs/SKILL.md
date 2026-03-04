---
name: reading-faber-logs
description: Read and query Faber task logs from outside a worktree. Use when you need to inspect what an agent did, extract specific information from a task log, or answer questions about a task's output.
---

# Reading Faber logs

Guidance on reading faber logs. Load the `using-faber` skill for the full CLI reference.

## Start with the diff, not the log

If you want to know what a task produced, `faber diff <taskId>` is almost always the right first move. It shows exactly what the agent committed -- nothing more. The log tells you the story of how it got there, which you usually don't need.

Only reach for the log when the diff isn't enough: when you need to know why a decision was made, whether tests passed, what the agent's closing summary said, or why a task failed.

## Always delegate to a sub-agent

Never load a task log into your own context. Spin up a sub-agent, give it the task ID and a specific question, and have it return only the answer. The sub-agent pays the context cost; you get a clean response.

Example prompt to the sub-agent:

> Read the log for Faber task @a3f2c1-fix-the-login-bug. Did the agent run the test suite, and if so, did they pass?

Keep the question narrow. "What did the agent do?" produces a wall of text. "Did the tests pass?" produces one sentence.

## Ask one question at a time

The log is a transcript. Reading it linearly looking for "anything interesting" is slow and unreliable. It works better to come in with a specific question and stop as soon as you have the answer.

Good questions to send a sub-agent:
- Did the test suite pass?
- What did the agent say at the end?
- Which files did it modify?
- Did any tool call produce an error?

Avoid open-ended requests like "summarise what the agent did" unless a human is genuinely asking for that. The diff is better for code review; the log is better for debugging a specific thing.
