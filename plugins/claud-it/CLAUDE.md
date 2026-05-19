# claud-it — Constitution

Goal: write great code for scalable, secure, maintainable systems.
The rules below are the guardrails — every skill, agent, and hook in
this plugin defers to them.

> **Operating principle:** Don't freelance. Follow the plan, surface
> choices, ask before deviating. Architecture discoveries mid-implementation
> escalate back to design.

## Scope tiers

Every change has a tier. Before any workflow runs, classify the diff and
set the tier via `/claud-it:scope`. When unsure between two tiers, pick
the higher one.

### experiment
Throwaway code, spike, prototype, exploration.

Workflow: none required. Skills run only when explicitly invoked.

### patch
Single-concern changes: bug fix, small refactor, dependency bump, copy change. 1–5 files.

Workflow: `/claud-it:review-pr`

### feature
New user-visible behavior: new API endpoint, new screen, new flow. 3–15 files, multi-PR.

Workflow:
- `/claud-it:requirements`
- `/claud-it:design`
- `/claud-it:plan`
- `/claud-it:review-pr` (per PR)
- `/claud-it:ship`

### system
Major changes: new subsystem, breaking change. 10+ files.

Workflow: feature workflow, plus `principal-ux` joins `/claud-it:design` when UI is involved.

(Auto-escalation triggers in the next section can also force this tier — see those rules.)

## Auto-escalation triggers

If the diff touches any of these, the tier is at least `feature`. If it
touches two or more, the tier is `system`. These rules override the
file-count heuristics in the previous section.

- **Authentication / authorization** — login flows, session handling, token validation, JWT signing
- **Secrets, tokens, API keys** — storage, retrieval, rotation, signing logic
- **Database schema migrations** — DDL, table alters, index changes
- **IAM policies** — role definitions, permission grants, infra access scoping
- **Billing / payments** — pricing, charge logic, refund flows, invoicing
- **Infrastructure** — CDK/Terraform/CloudFormation stacks, deployment configs, networking

Never silently work below the required tier — if a trigger fires, escalate
immediately and log the reason.

## Override

The user can override the auto-set tier any time via `/claud-it:scope <tier>`.
Respect the override even if it's below what auto-escalation requires —
but log a loud warning explaining what's being bypassed.

## Artifacts

Each phase writes an artifact to the consumer project (not this plugin's repo).

### Committed
- `docs/prd/<feature>.md` — requirements + scope (from `/claud-it:requirements`)
- `docs/design/<feature>.md` — architecture + data model + alternatives (from `/claud-it:design`)
- `docs/adr/NNNN-<title>.md` — single architecture decision, immutable, numbered
- `docs/ux/<feature>.md` — flows + screens + copy (from principal-ux, UI only)

### Gitignored
- `plans/<feature>.md` — task breakdown (from `/claud-it:plan`)
- `.claude/scope` — current tier marker
- `.claude/last-review` — review marker keyed by diff hash

## Model assignment

| Agent | Model |
|---|---|
| `staff-engineer` | Opus |
| `security-engineer` | Opus |
| `principal-ux` | Opus |
| `staff-tpm` | Sonnet |
| `code-reviewer` | Sonnet |
| `code-quality-reviewer` | Sonnet |
| `integ-test-author` | Sonnet |

Opus for high-stakes ambiguous judgment (architecture, security, UX).
Sonnet for structured technical work at PR frequency.

## Findings

Agents output findings; empty list means approved.

- **BLOCKER** — must fix (broken, unsafe, or violates constitution)
- **WARNING** — should fix (works but suboptimal)
- **SUGGESTION** — optional improvement

Each finding: severity, file:line, what's wrong, recommended fix.
