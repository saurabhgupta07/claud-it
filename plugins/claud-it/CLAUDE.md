# claud-it — Constitution

Authoritative rules for every claud-it agent. The dispatcher decides *when* to engage; this document defines *how* to behave once engaged.

**Don't freelance.** Follow the plan, surface choices, ask before deviating. Escalate architecture discoveries mid-implementation back to design.

## Scope tiers

Every code change has a tier. Classify before any workflow runs. When unsure between two tiers, pick the higher one.

### experiment

Throwaway code, spike, prototype, exploration.

Workflow: none. Skills run only when explicitly invoked.

### patch

Single-concern change: bug fix, small refactor, dependency bump, copy change. 1–5 files.

Workflow: `/claud-it:review-pr`.

### feature

New user-visible behavior: new API endpoint, new screen, new flow. 3–15 files, multi-PR.

Workflow:
- `/claud-it:requirements`
- `/claud-it:design`
- `/claud-it:plan`
- `/claud-it:review-pr` (per PR)
- `/claud-it:ship`

### system

Major change: new subsystem, breaking change. 10+ files. Auto-escalation triggers below can also force this tier.

Workflow: feature workflow, plus `principal-ux` joins `/claud-it:design` when UI is involved.

## Auto-escalation triggers

If the diff touches any of these, tier is at least `feature`. Two or more → `system`. These rules override file-count heuristics.

- Authentication / authorization
- Secrets, tokens, API keys
- Database schema migrations
- IAM policies
- Billing / payments
- Infrastructure (CDK, Terraform, CloudFormation, networking)

Never work below the required tier silently. Escalate and log the reason.

## Override

User can override the auto-set tier via `/claud-it:scope <tier>`. Respect it even when below what auto-escalation would require — but log a loud warning naming what's being bypassed.

## Artifacts

Each phase writes to the *consumer* project, not this plugin.

**Committed:**
- `docs/prd/<feature>.md` — requirements + scope
- `docs/design/<feature>.md` — architecture, data model, alternatives
- `docs/adr/NNNN-<title>.md` — single architecture decision, immutable
- `docs/ux/<feature>.md` — flows, screens, copy (UI only)

**Gitignored:**
- `plans/<feature>.md` — task breakdown
- `~/.claude/scopes/$CLAUDE_CODE_SESSION_ID` — current tier marker (session-keyed; one file per Claude session)
- `.claude/last-review` — review marker keyed by diff hash

## Findings

Output as a list. Empty list = approved. Each finding: `severity`, `file:line`, diagnosis, recommended fix.

Severities: **BLOCKER** (must fix — broken, unsafe, or violates constitution), **WARNING** (should fix unless explicitly accepted with reasoning), **SUGGESTION** (optional).

## Code conventions

- Handle every error explicitly. Catch every throw; log with context (what failed, what input, what state).
- Use structured leveled logging (debug / info / warn / error). No `console.log` or `print` for app logs.
- Never hardcode. Use constants, config, env, or a secret manager.
- Split aggressively. Single responsibility per function and file.
- Commit per plan task, not per feature. Smaller commits = better review surface.
