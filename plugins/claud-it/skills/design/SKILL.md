---
name: design
description: Designer + parallel design reviewers. Drafts a design doc from the PRD, then spawns staff-engineer + security-engineer (and principal-ux if UI is involved) in parallel to critique. Iterates until reviewers approve. Second step in feature and system workflows.
---

# /claud-it:design

You are the lead engineer designing how to build the feature. Read the PRD, draft a design, then run it through parallel review.

**Refer to CLAUDE.md for** artifact paths, scope tiers, model assignment, and findings vocabulary.

## Inputs

1. Read the session scope tier:
   ```bash
   head -n 1 "$HOME/.claude/scopes/$CLAUDE_CODE_SESSION_ID" 2>/dev/null | tr -d '[:space:]'
   ```
   The tier informs how much architecture rigor applies. If empty, prompt the user to run `/claud-it:scope` first and stop.
2. Read the PRD (per CLAUDE.md §Artifacts). If no PRD exists, prompt the user to run `/claud-it:requirements` first and stop.
3. Read the codebase areas the design will touch (use Grep/Glob).

## Detect UI involvement

The PRD's "Users and use cases" and "Functional requirements" usually signal UI involvement. If the design touches user-facing surfaces (screens, components, plugin display, CLI output that matters for UX), the change has UI.

If unclear, ask the user: `Does this change have a user-visible UI surface (web / mobile / CLI / glasses display)?`

**`principal-ux` joins review only when scope tier is `system` AND UI is involved (per CLAUDE.md §Scope tiers).** For `feature` tier with UI, ask the user whether to optionally include `principal-ux` — don't auto-include.

## Steps

1. Read the PRD and the relevant codebase areas.
2. Draft a design doc covering the Design format sections below.
3. Write the draft as `<slug>.md` in the design directory (per CLAUDE.md §Artifacts). Status: `draft`.
4. **Spawn design reviewers in parallel** (single message, 2 or 3 Agent tool calls):
   - `staff-engineer` (Opus) — always
   - `security-engineer` (Opus) — always
   - `principal-ux` (Opus) — only when tier is `system` AND UI is involved (or user explicitly opted in for `feature`+UI)
   Brief each agent with: design doc path, PRD path, the scope tier (string), project root.
5. Collect findings as they return.
6. **Synthesize** findings into a single report, grouped by section and severity. Log the iteration number and current BLOCKER count.
7. **Decide next move:**
   - No BLOCKERs → update design status to `confirmed`, recommend `/claud-it:plan` next.
   - BLOCKERs → revise the design addressing each one, then re-run step 4 (this is iteration 2, 3, …).
   - **Iteration cap:** if iteration 3 still has BLOCKERs, **stop and ask the user** how to proceed (split the feature, drop scope, push back on a finding, etc.). Don't loop indefinitely.
8. After confirmation, surface choices that warrant an ADR — concrete triggers:
   - Any item from "Alternatives considered" where the chosen path is non-obvious or reversible only at cost
   - Any choice touching CLAUDE.md auto-escalation categories (auth, secrets, migrations, IAM, billing, infra)
   - Any new primitive or external dependency introduced
   Offer to draft each as `NNNN-<title>.md` in the ADR directory (per CLAUDE.md §Artifacts).

## Design format

Markdown. All sections required — render `_N/A — <reason>_` if not applicable so downstream readers have a stable contract.

```markdown
# Design — <Title>

> <one-line summary mirroring the PRD>

## Context
What we're building, linked back to the PRD.

## Goals (recap from PRD)
Just the bullets, for self-contained reading.

## High-level approach
2–4 paragraphs. The chosen direction and *why*.

## Components and data flow
Diagram (ASCII or mermaid) + per-component description.

## Data model
Schemas, tables, message shapes. Migration notes if changing existing data.

## Interfaces
APIs (HTTP routes, function signatures, event shapes), with examples.

## Failure modes
What goes wrong, how the system responds, what the user sees. Include observability: what's logged (structured), what metrics are emitted, what alerts fire.

## Security considerations
Auth boundaries, secrets, IAM scope, trust boundaries.

## Performance and scalability
Expected load, hot paths, where bottlenecks would surface.

## Alternatives considered
At least two alternatives, with why we didn't pick them.

## Open questions
Anything still uncertain that needs resolution before /claud-it:plan.

---
*Design drafted <UTC ISO 8601>. Status: <draft | confirmed | needs-revision>.*
```

## What NOT to do

- Don't write the design without reading the PRD first.
- Don't skip review — every design feature runs the parallel panel.
- Don't run reviewers sequentially.
- Don't suppress reviewer findings.
- Don't skip "Alternatives considered" — even if only one alternative existed, document it.
- Don't include implementation details (specific variable names, line-by-line plans) — that's the plan phase.
- Don't make architecture decisions during plan or implementation — escalate back to this skill per the constitution's operating principle.
- Don't edit the PRD from this skill. If the design surfaces a requirements gap, surface it to the user and update the PRD via `/claud-it:requirements` (set its status to `needs-revision`).
