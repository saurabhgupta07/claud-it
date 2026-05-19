# claud-it — Constitution

> **This file is a stub.** Full constitution is Phase 2 of the build plan.
> See [`../../docs/build-plan.md`](../../docs/build-plan.md) for what goes here.

## Coming in Phase 2

- **Philosophy** — methodical-not-slow framing, why parallel review is essentially free
- **Scope tiers** — tweak / patch / feature / system definitions and file-count heuristics
- **Auto-escalation rules** — non-negotiable triggers (auth, secrets, migrations, IAM, billing, infra)
- **Override mechanism** — `/claud-it:scope <tier>` and `/claud-it:scope no-ceremony`
- **Artifact conventions** — `docs/prd/`, `docs/design/`, `docs/adr/`, `docs/ux/` committed; `plans/` and `.claude/scope` gitignored
- **Model assignment** — Opus for staff-eng / security / UX; Sonnet for code-reviewer / quality / TPM / test-author
- **Gating policy** — BLOCKER / WARNING / SUGGESTION semantics, when each gates by tier
- **Communication protocol** — structured agent output format
