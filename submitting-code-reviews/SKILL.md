---
name: submitting-code-reviews
description: "Submits finalized code review comments to a GitHub PR via the batch review API. Handles diff line mapping and API submission. Use when review comments have been drafted and are ready to post."
---

# Submitting Code Reviews

Takes finalized code review comments and submits them as a batch review on a GitHub pull request. This skill handles the mechanical work of mapping comments to diff lines and calling the GitHub API.

Load skills: giving-kind-feedback

## Prerequisites

- GitHub CLI (`gh`) must be installed and authenticated
- The PR has been identified (owner/repo and PR number are known)
- Review comments have been finalized

## Workflow

### 1. Suggest Review Event

Based on the finalized comments' intent labels, suggest a review event:

- If any comment is labelled "Blocking:" or "Important:", suggest **request changes**.
- If all comments are nits, minor, or thoughts, suggest **comment**.
- If there are no comments, suggest **approve**.

Acknowledge the submission request, then present the suggestion in plain language: "Ready to submit. Since a couple of these are blocking, I'd suggest **request changes**. Sound right?" The user can override.

**Stop here and wait for the user to confirm or override before proceeding.** Do not continue to Step 2 until the user responds.

Map the chosen event to the API value: "comment" = `COMMENT`, "request changes" = `REQUEST_CHANGES`, "approve" = `APPROVE`.

### 2. Validate Tone

Load the `giving-kind-feedback` skill and check each comment against its principles. Don't nitpick. Only intervene when a comment is harsh enough that it could genuinely land badly. When that happens, offer a rewrite and let the user choose.

### 3. List Changed Files

Get the list of files changed in the PR:

```bash
gh pr diff <number> --repo <owner>/<repo> --name-only
```

### 4. Map Line Numbers

The code review tool produces approximate line numbers that may be off by a few lines. This step must identify the exact right line for each comment, not just confirm the approximate line is in a hunk.

For each comment, extract the changed lines in the surrounding hunk from the PR diff. Use a window of +/-5 lines around the approximate target:

```bash
gh pr diff <number> --repo <owner>/<repo> | perl -ne '
  BEGIN { $target=42; $lo=$target-5; $hi=$target+5 }
  if (/^diff --git a\/<filepath> /) { $found=1; next }
  if ($found && /^diff --git/) { last }
  if ($found && /^@@.*\+(\d+)/) { $line=$1-1 }
  if ($found && /^\+\+\+ /) { next }
  if ($found && /^\+/) { $line++; print "$line: $_" if $line>=$lo && $line<=$hi }
  if ($found && /^[ ]/)  { $line++; print "$line: $_" if $line>=$lo && $line<=$hi }
'
```

This prints the numbered lines in the hunk window. Now read the output and pick the line that best matches what the comment is about. Consider the comment's content (what it suggests changing, what code it references) and select the specific line the author should look at. Do not default to the approximate line from the review tool.

If no lines appear in the output, the target is not in a changed hunk. Widen the window or list all changed lines for the file to find the nearest valid line:

```bash
gh pr diff <number> --repo <owner>/<repo> | perl -ne '
  if (/^diff --git a\/<filepath> /) { $found=1; next }
  if ($found && /^diff --git/) { last }
  if ($found && /^@@.*\+(\d+)/) { $line=$1-1 }
  if ($found && /^\+\+\+ /) { next }
  if ($found && /^\+/) { $line++; print "$line: $_" }
  if ($found && /^[ ]/)  { $line++; print "$line: $_" }
' | head -60
```

The `line` field in the GitHub review API refers to the line number in the file (not the diff position) when using `side: "RIGHT"`. Only lines that appear in the diff output (prefixed with `+` or ` `) are valid targets for the API.

For suggestion blocks that replace multiple lines, set `start_line` to the first line and `line` to the last. For single-line suggestions, `line` alone is sufficient.

### 5. Submit Batch Review

Submit all comments as a single review using the GitHub API. Always use a JSON payload piped via `--input -` (never use `-f` flags for nested structures — they break numeric types):

```bash
cat <<'PAYLOAD' | gh api repos/<owner>/<repo>/pulls/<number>/reviews --method POST --input -
{
  "event": "COMMENT",
  "body": "",
  "comments": [
    {
      "path": "src/foo.ts",
      "line": 42,
      "side": "RIGHT",
      "body": "Comment text.\n\n```suggestion\nreplacement line here\n```"
    },
    {
      "path": "src/bar.ts",
      "line": 15,
      "side": "RIGHT",
      "body": "Another comment."
    }
  ]
}
PAYLOAD
```

After successful submission, display the review URL.

### 6. Report Result

Confirm submission with:
- Number of comments posted
- Review type (COMMENT, REQUEST_CHANGES, APPROVE)
- Link to the review on GitHub

## Key Technical Notes

- **Always use `--input -`** for the `gh api` call. The `-f` flag converts numbers to strings, causing 422 errors from GitHub's API.
- **Use `line` + `side: "RIGHT"`** rather than `position`. The `line` field is the actual line number in the new file, which is easier to determine than diff-relative positions.
- **Pick the semantically correct line.** The code review tool's line numbers are approximate. Step 2 extracts surrounding context from the diff so you can select the exact line the comment is about. Don't blindly use the review tool's line number just because it falls within a hunk.
