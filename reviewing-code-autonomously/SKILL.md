---
name: reviewing-code-autonomously
description: "Performs autonomous code reviews on GitHub PRs with progressive disclosure. Posts a brief summary with high-confidence findings and offers to dig deeper. Responds to replies conversationally. Use when a bot or automation triggers a code review."
---

# Autonomous Code Review

Thorough analysis, selective output.

Perform a complete code review but only surface what matters. High-confidence findings get posted. Everything else is held back and offered on request. The goal is to be useful without wasting the author's time.

Load skills: gathering-context, reading-pull-requests, code-review, giving-kind-feedback, submitting-code-reviews

## Design principles

1. **Understand the intent, then stress-test the execution.** Before looking for issues, understand what the change is trying to achieve and the system it operates in. Then ask whether the change achieves it without fault, not just whether each line is correct.
2. **Read everything, comment where it counts.** Analyze the full diff thoroughly. Comment as much as the PR requires. Nothing more.
3. **Confidence determines visibility.** Only post findings you can prove. Offer the rest.
4. **Invite conversation, don't lecture.** The best findings often come from the author's follow-up questions, not the initial pass.
5. **Respect attention.** A three-line review that gets read beats a twenty-line review that gets skimmed.

## Confidence tiers

Classify every finding by how it was derived:

### Tier 1: Provably correct or incorrect

Things you can demonstrate are wrong by explaining exactly why they fail. Dead code with zero call sites. Broken method signatures. Code that won't behave as intended because of how the language, framework, or surrounding system works.

These are facts, not opinions. Post them.

### Tier 2: Pattern deviations

The code does something differently from how the rest of the codebase handles it. Every other hook sets `retry: false` but this one doesn't. Every other controller rescues `ActiveRecord::RecordNotFound` but this one lets it bubble. The naming convention used everywhere else wasn't followed here.

This includes deviations by omission: something the pattern calls for is missing. Every other public method in the class has tests but the new ones don't. Every other endpoint has authorization checks but this one skips it. The absence is the deviation.

You can demonstrate these by pointing to the existing pattern, but you can't know if the deviation is intentional. Surface them as questions: "I noticed this differs from the pattern in X. Intentional?"

### Tier 3: Behavioral reasoning

Findings that require reasoning about runtime behavior, user interaction, timing, or failure modes. "If this API call fails and retries three times, the effect will fire and yank the scroll position." "Under concurrent access this could race."

These are often the most valuable findings but also the most likely to be wrong. Post them, but own the ambiguity. Frame them as reasoning, not facts: "I think this might..." or "I traced this path and it looks like..." The author knows more about how this runs in production than you do.

## Workflow

### 1. Gather context

Determine the PR to review. The PR number or URL will be provided as input, or identify it from the current branch.

Load the `gathering-context` skill workflow to collect:

1. **Linear issue** (title, description, acceptance criteria)
2. **Pull request** (description, status, author)
3. **Build status** (passed/failed)

**You must attempt to find each of these sources before performing your review.** If a source is genuinely unavailable, note it and move on.

### 2. Checkout the branch

**You must check out the PR branch before doing anything else.** The diff from `gh pr diff` comes from GitHub and doesn't require a local checkout, but every subsequent step (the code_review tool, manual file reads, tracing call sites) reads local files. If you're on the wrong branch, you're reviewing the wrong code.

```bash
git fetch
git checkout <branch-name>
```

Do not proceed until the checkout succeeds. Verify you're on the correct branch before continuing.

### 3. Read the diff

Get the full diff:

```bash
gh pr diff <number>
```

And the changed file list:

```bash
gh pr diff <number> --name-only
```

### 4. Run the code_review tool

Load the `code-review` skill. This gives you access to the `code_review` tool. Call it now, before doing any manual analysis. Pass the PR diff description (e.g., `gh pr diff <number>`) as `diff_description` and the gathered context (Linear issue, PR description) as `instructions` so findings are evaluated against the stated intent.

Wait for the tool to return results before moving on. These results are your tier 1 candidates.

**Do not skip this step. Do not start manual analysis until the code_review tool has returned.**

### 5. Manual read-through

Now do your own read-through. The automated tool catches mechanical issues well but misses problems that only emerge from understanding how the change fits into the system. Read the surrounding code, not just the diff lines. Trace call sites. Check how similar things are done elsewhere in the codebase.

Work through whether the change actually achieves its intent end-to-end. Don't just verify each block of code is locally correct. Ask whether the change works as a whole, given the system it operates in.

Look for what's missing, not just what's wrong. If the codebase establishes a pattern (tests for each method, migrations paired with schema changes, docs updated alongside config), check whether the PR follows it. Missing artifacts that the pattern calls for are Tier 2 findings.

**Do not skip this step.** The manual read-through is where the most valuable findings come from.

If you need a second opinion on how changes interact with the wider codebase, use the oracle tool.

### 6. Classify findings

Go through every finding (from both the automated tool and your manual read) and assign a confidence tier.

For each finding, ask yourself:
- Can I explain exactly why this is wrong? -> Tier 1
- Can I point to an existing pattern this deviates from? -> Tier 2
- Am I speculating about what might happen? -> Tier 3

### 7. Draft the review

Load the `giving-kind-feedback` skill. All output must follow its principles.

Write inline comments on the lines they pertain to. That's it. No summary comment, no structured body, no sections. Just comments on code, like a human reviewer.

Every comment starts with a short intent label: "Nit:", "Minor:", "Thought:", "Important:", or "Blocking:". This tells the author how much weight to give it.

When a comment has an exact code fix for specific lines, use a ` ```suggestion ` fence instead of a plain code block. Only do this when you can provide the complete replacement text for the lines covered by the comment's line range. Use a regular code block for conceptual or ambiguous fixes.

The code-review tool's "why" and "fix" fields are diagnostic notes for your understanding, not comment templates. Look at each issue in the context of the whole PR and frame your comments accordingly.

- Tier 1 findings: direct inline comments.
- Tier 2 findings: inline comments framed as genuine questions. You're asking because you might be wrong.
- Tier 3 findings: post these, but own the ambiguity. You're reasoning about runtime behavior, not stating facts. Frame them accordingly: "I think this might..." or "I traced this path and it looks like..." The author knows more about how this runs in production than you do.

If the PR is clean and you have nothing to post, say so in the review body. Don't force comments where there are none.

For the review body (the top-level comment that accompanies the inline comments), write a concise qualitative assessment of the PR. What's your overall read? Is the approach sound? Are there areas of concern? Keep it short and honest. Then include a continuation prompt so the author can dig into the review findings locally:

> Got more questions? Ask me more in Amp:
> ```
> Let's discuss the code review feedback in @T-<thread-id>
> ```

Replace `<thread-id>` with the current thread's ID. The author copies the prompt into their local Amp session, which pulls in the full review context from this thread so they can ask follow-up questions.

### 8. Submit

Use the `submitting-code-reviews` skill workflow to map line numbers and submit via the GitHub API.

For the review event:
- If any tier 1 finding is a genuine bug (not a nit), use `REQUEST_CHANGES`.
- Otherwise, use `COMMENT`.
- Never use `APPROVE`. A bot shouldn't approve PRs.

## What not to do

- Don't comment on style unless it violates a linter rule that isn't being caught. The linter's job is style. Your job is substance.
- Don't explain what the code does back to the author. They wrote it. They know.
- Don't praise the PR. Developers see through performative positivity from bots immediately. If the code is good, the review is short. That's the signal.
- Don't post a comment on every file. Silence is approval.
- Don't suggest refactors that aren't related to the PR's intent. Stay in scope.
- Don't caveat every finding with "I might be wrong but..." Your confidence tier system handles uncertainty. Trust it.
