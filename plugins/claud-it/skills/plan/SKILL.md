---
name: plan
description: Break a confirmed design into PR-sized tasks. Writes plans/<slug>.md and spawns staff-tpm for review. Third step in feature and system workflows.
---

# /claud-it:plan

You decompose a confirmed design into an executable plan — ordered tasks, each PR-sized.

**Refer to CLAUDE.md for** artifact paths and the operating principle (follow the plan exactly during implementation; escalate architecture discoveries back to design).

## Inputs

1. Read `<project-root>/.claude/scope` to know the tier (informs granularity).
2. Read the design doc (per CLAUDE.md §Artifacts). Status must be `confirmed`. If not, stop and tell the user to confirm the design first.
3. Read the PRD (per CLAUDE.md §Artifacts) for success criteria.
4. Skim the codebase areas the plan will touch.

## Steps

1. Decompose the design into ordered tasks. Each task should fit one PR:
   - Single concern (one logical change)
   - ~100–300 LOC
   - Independent enough to merge atomically
2. Identify which tasks can run in parallel (no shared files or sequential dependencies).
3. Write the plan to the plans directory (per CLAUDE.md §Artifacts) as `<slug>.md`. Status: `draft`.
4. **Spawn `staff-tpm`** to review the plan for completeness vs design/PRD, parallelization opportunities, and sequencing deadlocks. Brief it with: plan path, design path, PRD path, project root.
5. **Process findings:**
   - No BLOCKERs → mark plan status `confirmed`. Recommend the user start with task 1 (or the first parallel batch).
   - BLOCKERs → revise the plan addressing each; re-run step 4.
   - **Iteration cap:** if iteration 3 still has BLOCKERs, stop and ask the user how to proceed.
6. Print the file path and a summary: total tasks, parallelizable groups, estimated PR count.

## Plan format

Markdown. Structure:

```markdown
# Plan — <Title>

> <one-line summary mirroring the PRD>

## Overview
2–3 sentences. What we're building, in what order, why this order.

## Prerequisites
Anything that must exist before task 1 (decisions, dependencies, env setup).

## Tasks

### Task 1: <short title>
- **Goal:** what this PR accomplishes
- **Files:** which files change (paths)
- **Depends on:** task numbers (or "none")
- **Parallel with:** task numbers that can run alongside (or "none")
- **Done when:** observable check (test passes, screen renders, endpoint returns, etc.)

### Task 2: <short title>
...

## Cleanup (post-merge)
Things to remove after rollout (feature flags, shims, dual-writes).

---
*Plan generated <UTC ISO 8601>. Status: <draft | confirmed | needs-revision>.*
```

## Behavior

- Tasks are PR-sized, never half-PRs or multi-PRs.
- The order is the recommended sequential order. Where tasks are parallel-safe, note it explicitly.
- The plan file is gitignored — it's working state, not a permanent deliverable.

## What NOT to do

- Don't write the plan without a confirmed design.
- Don't expand scope beyond the design — gaps go back to `/claud-it:design` (mark its status `needs-revision`).
- Don't propose tasks that can't fit in a single PR. If a task is too big, split it.
- Don't suppress dependencies between tasks to make them look parallel.
- Don't edit the design or PRD from this skill.
