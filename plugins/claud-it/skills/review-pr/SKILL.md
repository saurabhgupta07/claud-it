---
name: review-pr
description: Run the parallel review panel (code-reviewer + code-quality-reviewer + security-engineer) against the current diff. Synthesizes findings and writes a review marker that pre-commit hooks check. Use after coding a PR, before committing.
---

# /claud-it:review-pr

The workhorse skill. Runs three reviewer agents in parallel against the current diff and reports findings. Writes a review marker the pre-commit hook reads.

**Refer to CLAUDE.md for** scope tiers, findings vocabulary (BLOCKER/WARNING/SUGGESTION), and which BLOCKERs gate at which tier.

## Steps

1. **Check scope.** Read the session scope tier:
   ```bash
   head -n 1 "$HOME/.claude/scopes/$CLAUDE_CODE_SESSION_ID" 2>/dev/null | tr -d '[:space:]'
   ```
   If empty, prompt the user to run `/claud-it:scope` first and stop.
2. **Get the diff.** Run `git diff HEAD` and `git diff --staged`. If the working tree is clean, print "No changes to review" and stop.
3. **Compute diff hash.** SHA256 over the output of `git diff HEAD` (covers both staged and unstaged), LF-normalized. This must be deterministic so the pre-commit hook can verify the marker is current.
4. **Spawn three reviewers in parallel** — single message, three Agent tool calls (parallel is required; sequential breaks the "independent perspectives" principle):
   - `code-reviewer` (Sonnet) — correctness
   - `code-quality-reviewer` (Sonnet) — maintainability
   - `security-engineer` (Opus) — security
   Brief each agent with: the diff (or instructions to run `git diff HEAD`), the scope tier (string, read in step 1), and the project root path so they can read CLAUDE.md.
5. **Collect findings** as they return.
6. **Synthesize** into a single report:
   - Group by file, then by severity (BLOCKERs first)
   - Note which agent flagged each finding (e.g., "[security-engineer]")
   - De-duplicate if multiple agents flagged the same line for similar concerns (different concerns at the same line stay separate)
7. **Apply gating** per the current scope tier (see CLAUDE.md):
   - `experiment` — all findings advisory
   - `patch` / `feature` / `system` — BLOCKERs gate the commit
8. **Write the review marker** at `<project-root>/.claude/last-review` (format below).
9. **Print the report.**
   - BLOCKERs in a gating tier: end with `Action required: fix the BLOCKERs above, then re-run /claud-it:review-pr.`
   - No BLOCKERs: `✓ Reviewed by 3 agents. <N> WARNINGs, <M> SUGGESTIONs. Safe to commit.`

## Review marker format

Plain text at `<project-root>/.claude/last-review`:

```
<sha256-of-diff>
# reviewed 2026-05-19T11:45:00-07:00
# tier: feature
# blockers: 0
# warnings: 3
# suggestions: 5
```

- **Line 1:** SHA256 (hex, lowercase) of `git diff HEAD` output, LF-normalized. Must match how Step 3 computes it.
- **Lines 2+:** comments. Comment fields after `# ` form key/value pairs the hook reads (`blockers: <n>` is what gates). Timestamps use ISO 8601 with explicit timezone (UTC recommended for portability).

The pre-commit hook reads:
1. Line 1 — does it match the current diff hash? If not, you've changed files; review is stale; commit refused.
2. `blockers:` value — if > 0 in a gating tier, commit refused.

## Behavior

- Parallel spawn is required.
- If any agent fails (timeout, error), continue with the others but flag the gap in the report — don't silently succeed.
- Write the review marker **after** all three agents complete, regardless of BLOCKERs (the marker records what happened; the hook decides what to do with it).
- Exit non-zero if any BLOCKER is present in a gating tier; zero otherwise.

## What NOT to do

- Don't run reviewers sequentially.
- Don't suppress an agent's finding to keep the report tidy — surface everything.
- Don't decide gating yourself — use the tier read in step 1, apply CLAUDE.md rules.
- Don't write the review marker if you skipped any reviewer.
