---
name: ship
description: Final gate before merging a feature or system change. Verifies PRD/design/plan are confirmed and all PRs were reviewed, then spawns integ-test-author to generate integration tests. Last step in feature and system workflows.
---

# /claud-it:ship

You are the final gate. Verify all phase artifacts are complete and confirmed, then generate integration tests for the feature.

**Refer to CLAUDE.md for** artifact paths, scope tiers, findings vocabulary, and the operating principle.

## Inputs

1. Read the session scope tier:
   ```bash
   head -n 1 "$HOME/.claude/scopes/$CLAUDE_CODE_SESSION_ID" 2>/dev/null | tr -d '[:space:]'
   ```
   Must be `feature` or `system`. If `patch` or `experiment`, this skill is not the right one — explain and stop. If empty, prompt the user to run `/claud-it:scope` first and stop.
2. Read the PRD, design doc, and plan (per CLAUDE.md §Artifacts).
3. Read `<project-root>/.claude/last-review` if it exists.

## Steps

1. **Verify phase completeness:**
   - PRD status must be `confirmed`.
   - Design status must be `confirmed`.
   - Plan status must be `confirmed`.
   - If any is missing or not confirmed, list what's missing and stop.
2. **Verify reviews happened.** Check `<project-root>/.claude/last-review` exists. Per `/claud-it:review-pr`'s marker format: line 1 is `git diff HEAD` SHA256 (LF-normalized); the `blockers:` comment field must be `0`. If line 1 doesn't match the current diff or blockers > 0, stop and direct the user to re-run review. For multi-PR features, the marker is gitignored and only reflects the most recent PR — ask the user to attest: `Did every PR for this feature pass /claud-it:review-pr with zero BLOCKERs?` Record the attestation in the design doc's "Open questions" so there's an audit trail:

```markdown
- ATTESTED: all PRs for this feature reviewed with zero BLOCKERs. <user> <UTC ISO 8601>. PRs: <list of commit hashes or PR numbers>.
```
3. **Spawn `integ-test-author`.** Brief it with: PRD path, design path, plan path, project root, current branch.
4. **Handle the agent's output:**
   - **Mode A (tests written)** → list the new test files and proceed to step 5.
   - **Mode B (framework proposal)** → relay the proposal to the user and stop. The framework decision must go through `/claud-it:design` (mark its status `needs-revision`); shipping cannot proceed without integ tests or an explicit user waiver (see Waivers below).
5. **Run the tests** (Mode A only). Execute the project's test command (e.g., `npm test`, `pytest`) and report results.
6. **Final report:**
   - All tests pass → `Ship gate cleared. Tests pass; all reviews confirmed. Safe to merge.`
   - Any test fails → list failures, recommend fixes, **do not approve ship**.
   - Tests can't run (env, dependency, infra not available) → flag for user; ship stays blocked until tests run.

## Waivers

If the user wants to waive integ tests (e.g., framework setup will land as a separate feature), require an explicit confirmation flow:

1. Log loudly: `⚠️ Waiving integration tests bypasses the ship gate's primary safety check. Reason required.`
2. Ask the user: `Why are tests being waived?` Capture the reason.
3. Ask: `Confirm waiver — type "I waive integ tests for <feature-slug>: <reason>" to proceed.`
4. If the user confirms with the exact phrase, record the waiver in the design doc's "Open questions":

```markdown
- WAIVED: integration tests deferred. Reason: <captured reason>. Approved by <user> <UTC ISO 8601>.
```

Without the explicit confirmation phrase, the ship gate stays blocked.

## Behavior

- This skill gates; it does **not** commit, push, or merge — the user takes the final merge action.
- If the gate is not cleared, **do not** print the cleared message. Print exactly which gate failed and the next action needed.

## What NOT to do

- Don't bypass verification — if any artifact is incomplete, stop.
- Don't merge or push.
- Don't accept Mode B silently — framework decisions escalate to design.
- Don't suppress test failures to get the gate cleared.
- Don't edit production code from this skill.
- Don't approve ship for `patch` or `experiment` scope — those don't go through this gate.
