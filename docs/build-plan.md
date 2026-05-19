# claud-it — Build Plan

> Living document. Update each phase as it completes. Mark complete with ✅ and date.

## Goal

A Claude Code plugin marketplace that ships a methodical SDLC:

- **Audit panel**: every PR reviewed by code-reviewer + code-quality-reviewer + security-engineer in parallel.
- **Scope-aware ceremony**: tweak / patch / feature / system tiers determine which BLOCKERs gate.
- **Durable artifacts**: requirements, design, ADRs become real committed markdown in the consumer project.
- **Mechanical gates**: hooks prevent commits/pushes without the prescribed review.

Built for solo use first; portable to teams later.

---

## Phase 0 — Locked decisions

| Decision | Choice |
|---|---|
| Repo name | `claud-it` |
| Local path | `~/code/claud-it/` |
| Install pattern | Plugin marketplace (`/plugin marketplace add`) |
| Plugin namespace | `/claud-it:*` |
| Scope tiers | tweak / patch / feature / system |
| Auto-escalation triggers | auth, secrets, migrations, IAM, billing, infra |
| Phase artifacts | committed in project's `docs/{prd,design,adr,ux}/` |
| Working state | gitignored in `plans/` and `.claude/scope` |
| Gating policy | BLOCKERs gate in feature/system; advisory in tweak/patch |
| Model assignment | Opus for staff-eng / security / UX; Sonnet for code-reviewer / quality / TPM / test-author |
| Gating hooks | pre-commit-checks, pre-push-confirm-main, block-without-review |

---

## Phase 1 — Skeleton ✅ 2026-05-18

**Deliverable**: empty but installable plugin marketplace repo.

- [x] `~/code/claud-it/` created
- [x] `README.md` with philosophy + install + roster
- [x] `.claude-plugin/marketplace.json`
- [x] `plugins/claud-it/plugin.json`
- [x] `plugins/claud-it/CLAUDE.md` (stub, full content in Phase 2)
- [x] `docs/build-plan.md` (this file)
- [x] `.gitignore`
- [x] `git init`, first commit

After Phase 1: `/plugin marketplace add` works against this repo. Nothing wired yet.

---

## Phase 2 — Constitution (`plugins/claud-it/CLAUDE.md`) ✅ 2026-05-18

**Estimate**: 45 min. **Highest-leverage hour** of the project.

Sections to write:

1. **Philosophy** — methodical-not-slow framing; parallel review = ~90s wall-clock; why discipline has no cost in this paradigm
2. **Scope tiers** — tweak / patch / feature / system definitions table with file-count heuristics
3. **Auto-escalation rules** — non-negotiable triggers (auth / secrets / migrations / IAM / billing / infra)
4. **Override mechanism** — `/claud-it:scope <tier>` and `/claud-it:scope no-ceremony`
5. **Artifact conventions** — `docs/prd/`, `docs/design/`, `docs/adr/`, `docs/ux/` committed; `plans/` and `.claude/scope` gitignored
6. **Model assignment table** — Opus for high-stakes, Sonnet for high-frequency
7. **Gating policy** — BLOCKER / WARNING / SUGGESTION semantics; tier × severity matrix
8. **Communication protocol** — structured agent output format

After Phase 2: every downstream skill/agent has a constitution to reference.

---

## Phase 3 — Agent fleet

**Estimate**: ~2 hours. Order matters — first three unblock `/claud-it:review-pr`.

| Order | Agent | Model | Tools | Phase used in |
|---|---|---|---|---|
| 1 | `code-quality-reviewer` | Sonnet | Read, Grep, Glob | Per-PR |
| 2 | `code-reviewer` | Sonnet | Read, Grep, Glob, Bash | Per-PR (migrated from existing) |
| 3 | `security-engineer` | Opus | Read, Grep, Glob, Bash | Per-PR + design |
| 4 | `staff-engineer` | Opus | Read, Grep, Glob, WebFetch | Design |
| 5 | `staff-tpm` | Sonnet | Read, Grep, Glob | Plan |
| 6 | `principal-ux` | Opus | Read, Grep, Glob, WebFetch | Design (UI only) |
| 7 | `integ-test-author` | Sonnet | Read, Write, Edit, Bash, Glob, Grep | Ship |

Each agent file structure:

```
---
name: <agent-name>
description: <when to invoke>
tools: <scoped tools>
model: <opus|sonnet|haiku>
---

# Role
# What to review (or generate)
# Communication Protocol
# What NOT to do
```

After Phase 3: 7 standalone reviewer/author agents, each spawnable.

---

## Phase 4 — Skills

**Estimate**: ~2 hours. Order ensures `/claud-it:review-pr` works first.

| Order | Skill | What it does | Spawns |
|---|---|---|---|
| 1 | `/claud-it:scope` | View/set current scope, run auto-escalation | (utility) |
| 2 | `/claud-it:review-pr` | Workhorse — runs every PR | code-reviewer + code-quality-reviewer + security-engineer (parallel) |
| 3 | `/claud-it:requirements` | PM mode — clarifying Qs, writes PRD | (skill itself) |
| 4 | `/claud-it:design` | Drafts design + spawns reviewers | staff-engineer + security-engineer (+ principal-ux if UI) |
| 5 | `/claud-it:plan` | Task breakdown → `plans/` | staff-tpm |
| 6 | `/claud-it:ship` | Final gate before merge | integ-test-author |

After Phase 4: full SDLC workflow runnable end-to-end.

---

## Phase 5 — Hooks

**Estimate**: ~30 min. Three shell scripts, no LLM.

- `pre-commit-checks.sh` — typecheck + lint + secret-regex-scan
- `pre-push-confirm-main.sh` — interactive confirm on main pushes
- `block-without-review.sh` — refuse commit if `.claude/last-review` absent or stale

Wired in `settings/settings.template.json` to `PreToolUse` on `Bash` matching `git commit` / `git push`.

After Phase 5: you literally cannot commit without going through `/claud-it:review-pr`.

---

## Phase 6 — Validation on Cirrus

**Estimate**: ~1 hour. Real test against real code.

1. `/claud-it:review-pr` on the Cirrus `src/main.ts` voice loop — should catch hardcoded API key, missing error paths, etc.
2. `/claud-it:requirements` on the reminders feature
3. `/claud-it:design` on the reminder backend
4. Adjust agent prompts based on what was useful vs noisy

After Phase 6: validated on real code, ready for daily use.

---

## Phase 7 — Cirrus-specific overlay

**Estimate**: ~30 min.

Create `/Users/saurabhgupta/workplace/Cirrus/CLAUDE.md` with:

- Even Hub plugin gotchas (port from existing memory)
- Backend conventions (CDK-only, secrets in SSM, no keys in code)
- Plugin packaging rules (`eh pack -c`, mic permission triggers install)
- Voice-loop architecture summary

After Phase 7: Cirrus-specific rules in place; agents reviewing Cirrus code know the local quirks.

---

## Time + cost estimate

| Phase | Time | Token cost |
|---|---|---|
| 1. Skeleton | 30 min | ~$0.20 |
| 2. Constitution | 45 min | ~$0.50 |
| 3. Agents | 2 hours | ~$2 |
| 4. Skills | 2 hours | ~$2 |
| 5. Hooks | 30 min | ~$0.30 |
| 6. Validation | 1 hour | ~$1 |
| 7. Cirrus overlay | 30 min | ~$0.30 |
| **Total** | **~7.5 hours** | **~$6** |

---

## Open design questions (revisit during Phase 4-5)

- **Auto-push after review+commit.** Currently commits sit local until manually pushed. Options to decide between:
  - `PostToolUse` hook on `Bash git commit` → auto `git push` to current branch's upstream
  - `/claud-it:ship` skill includes push as a final step
  - CLAUDE.md rule: "after every review-passing commit, push to remote"
  - Combination — push automated for non-main branches; main requires explicit confirmation (matches `pre-push-confirm-main.sh` hook in Phase 5)
- **Where to write a "I just committed" marker.** `block-without-review.sh` needs to know if `/claud-it:review-pr` was run for the current diff. Marker file at `.claude/last-review`? With hash of the diff so stale markers don't pass?
- **`/claud-it:scope` skill UX.** Skill must log the chosen tier prominently so user sees what got picked — e.g., `📋 Chosen tier: feature (3 files match, new API endpoint detected). Override: /claud-it:scope <tier>`. Status bar shows the active tier (🧪/🔧/🎯/⚠️) per-project from `.claude/scope` marker.

## Progress log

| Date | Phase | Notes |
|---|---|---|
| 2026-05-18 | 1 | Skeleton committed. README, marketplace.json, plugin.json, stub CLAUDE.md, this plan, gitignore. |
| 2026-05-18 | 1 | Pushed to github.com/saurabhgupta07/claud-it (public). Plugin renamed sdlc → claud-it. |
| 2026-05-18 | 2 | Constitution written: goal + operating principle + 6 sections (scope, escalation, override, artifacts, models, findings). 102 lines, 513 words. |
