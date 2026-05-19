# claud-it

> Every change earns its commit through an audit panel of specialist agents.

`claud-it` is a Claude Code plugin marketplace that wraps your development in a methodical SDLC. Every PR runs through a parallel panel of reviewers — code, code-quality, and security — that vouch for the change before it ships. Bigger work (features, system changes) gets the full pipeline: requirements → design → plan → implement → review → ship, with appropriate specialists reviewing at each stage.

## Philosophy

- **Methodical, not slow.** Parallel agent spawns finish in ~90 seconds. Discipline has no real time cost when the team is AI.
- **Tiered ceremony.** Every PR runs the full review fleet; scope (tweak / patch / feature / system) controls what's gating vs advisory.
- **Real artifacts.** PRDs, design docs, ADRs live as committed markdown in each project's `docs/`. Plans are ephemeral and gitignored.
- **Independent perspectives.** Review agents run in fresh contexts — they can't see the writer's reasoning, can't be biased into approval.

## Install

```bash
# In Claude Code
/plugin marketplace add saurabhgupta07/claud-it
/plugin install sdlc@claud-it
```

## Quick start

```
/sdlc:scope feature                    # declare scope for this change
/sdlc:requirements "add reminders"     # PM gathers requirements → docs/prd/
/sdlc:design                           # designer drafts → reviewers critique → docs/design/
/sdlc:plan                             # task breakdown + TPM review → plans/
# ... implement ...
/sdlc:review-pr                        # parallel audit: code + quality + security
/sdlc:ship                             # final gate: integ tests + sign-off
```

## Roster

| Agent | Model | Role |
|---|---|---|
| `staff-engineer` | Opus | Architecture & design review |
| `security-engineer` | Opus | Auth boundaries, secrets, IAM, injection |
| `principal-ux` | Opus | UI/UX design review (conditional) |
| `staff-tpm` | Sonnet | Task sequencing, dependencies, risk ordering |
| `code-reviewer` | Sonnet | Per-PR bug & logic review |
| `code-quality-reviewer` | Sonnet | DRY, naming, maintainability, type tightness |
| `integ-test-author` | Sonnet | Generates integration tests for new PRs |

## Status

**v0.0.1 — Phase 1 (skeleton).** Full build plan in [`docs/build-plan.md`](./docs/build-plan.md).

## Project structure (target — v0.0.1 has skeleton only)

```
claud-it/
├── README.md
├── .claude-plugin/
│   └── marketplace.json
├── docs/
│   └── build-plan.md
└── plugins/
    └── sdlc/
        ├── plugin.json
        ├── CLAUDE.md                   (stub today, full in Phase 2)
        ├── skills/                     (Phase 4)
        │   ├── scope/
        │   ├── requirements/
        │   ├── design/
        │   ├── plan/
        │   ├── review-pr/
        │   └── ship/
        ├── agents/                     (Phase 3)
        │   ├── staff-engineer.md
        │   ├── security-engineer.md
        │   ├── principal-ux.md
        │   ├── staff-tpm.md
        │   ├── code-reviewer.md
        │   ├── code-quality-reviewer.md
        │   └── integ-test-author.md
        └── hooks/                      (Phase 5)
            ├── pre-commit-checks.sh
            ├── pre-push-confirm-main.sh
            └── block-without-review.sh
```
