# claud-it

A Claude Code plugin marketplace that turns Claude into a disciplined SDLC team — PM, designer, TPM, and a panel of reviewers — that ships every change through the right amount of ceremony.

You declare the **scope** of your change, and `claud-it` decides which skills, agents, and hooks fire. Tiny tweak? Just runs a review panel. New feature? Walks you from requirements through design, plan, implement, review, ship — with specialist agents reviewing in parallel at each stage.

## Install

```bash
# In Claude Code
/plugin marketplace add saurabhgupta07/claud-it
/plugin install claud-it@claud-it
```

## How you use it

Every change starts the same way: **set a scope**. The scope determines which workflow runs.

```
/claud-it:scope           # Claude classifies your diff for you
/claud-it:scope feature   # or pick the tier explicitly
```

Either you pick, or Claude decides — both are valid entry points. Claude applies the auto-escalation triggers below in either case.

### See the current scope in your status line

So you always know which tier is governing your work, wire the scope into Claude Code's status line. Add this to `~/.claude/settings.json` (global) or your project's `.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "scope=$(cat .claude/scope 2>/dev/null || echo 'unset — run /claud-it:scope'); echo \"🎯 scope: $scope\""
  }
}
```

The line refreshes every turn — change scope with `/claud-it:scope <tier>` and the status bar updates.

| Tier | When to use | Workflow |
|---|---|---|
| `experiment` | Throwaway code, spike, prototype | None. Skills run only when invoked. |
| `patch` | Bug fix, small refactor, copy change (1–5 files) | `/claud-it:review-pr` |
| `feature` | New user-visible behavior (3–15 files, multi-PR) | requirements → design → plan → implement → review-pr → ship |
| `system` | New subsystem, breaking change (10+ files) | feature workflow + `principal-ux` when UI is involved |

Auto-escalation: touching auth, secrets, migrations, IAM, billing, or infra forces tier ≥ `feature` (two triggers → `system`). See [`plugins/claud-it/CLAUDE.md`](./plugins/claud-it/CLAUDE.md) for the full rules.

## Skills (slash commands)

| Command | What it does |
|---|---|
| `/claud-it:scope [tier]` | Classify the diff and write `.claude/scope`. Run this first. |
| `/claud-it:requirements "<idea>"` | PM interviews you and writes `docs/prd/<slug>.md`. |
| `/claud-it:design` | Lead engineer drafts a design from the PRD, then `staff-engineer` + `security-engineer` (+ `principal-ux` if UI) critique in parallel until approved. Writes `docs/design/<slug>.md`. |
| `/claud-it:plan` | Decomposes the design into PR-sized tasks. `staff-tpm` reviews sequencing/risk. Writes `plans/<slug>.md` (gitignored). |
| `/claud-it:review-pr` | The workhorse. Spawns `code-reviewer` + `code-quality-reviewer` + `security-engineer` in parallel against the current diff, synthesizes findings, writes a review marker. The pre-commit hook reads this marker. |
| `/claud-it:ship` | Final gate. Verifies all artifacts are confirmed, then `integ-test-author` generates integration tests. |

## Agents (the review panel)

Spawned by the skills above — you don't invoke them directly.

| Agent | Model | Role |
|---|---|---|
| `staff-engineer` | Opus | Architecture & design review |
| `security-engineer` | Opus | Auth, secrets, IAM, injection, supply chain |
| `principal-ux` | Opus | UI/UX flows, copy, accessibility (UI changes only) |
| `staff-tpm` | Sonnet | Task sequencing, dependencies, risk ordering |
| `code-reviewer` | Sonnet | Per-PR bug & logic review |
| `code-quality-reviewer` | Sonnet | DRY, naming, maintainability, type tightness |
| `integ-test-author` | Sonnet | Generates integration tests at ship time |

Each agent runs in a fresh context — reviewers can't see the writer's reasoning, so they can't be biased into approval. Findings come back as `BLOCKER` / `WARNING` / `SUGGESTION`, with file:line and recommended fix.

## Hooks (mechanical gates)

Installed automatically with the plugin. They fire on shell events, not Claude's discretion.

| Hook | Trigger | Behavior |
|---|---|---|
| `pre-commit-checks.sh` | `git commit` | Secret-pattern scan, typecheck, lint. Blocks the commit on failure. |
| `block-without-review.sh` | `git commit` | Refuses commit unless `/claud-it:review-pr` was run on the current diff (matched by hash). |
| `pre-push-confirm-main.sh` | `git push` | Warns on push to `main`/`master`/`trunk`/`develop`; blocks force-pushes to those branches. |

## Artifacts

`claud-it` produces real, durable artifacts in the **consumer project** (not this repo):

**Committed** — `docs/prd/<feature>.md`, `docs/design/<feature>.md`, `docs/adr/NNNN-<title>.md`, `docs/ux/<feature>.md`

**Gitignored** — `plans/<feature>.md`, `.claude/scope`, `.claude/last-review`

## A typical feature flow

```
/claud-it:scope feature
/claud-it:requirements "users can set reminders"   # → docs/prd/reminders.md
/claud-it:design                                   # → docs/design/reminders.md
/claud-it:plan                                     # → plans/reminders.md
# implement task 1 — commit (hooks fire)
/claud-it:review-pr                                # before each commit
# ... continue per plan task ...
/claud-it:ship                                     # final gate
```

For a `patch`, this collapses to: edit → `/claud-it:review-pr` → commit.

## Project structure

```
claud-it/
├── README.md
├── .claude-plugin/marketplace.json
└── plugins/claud-it/
    ├── plugin.json
    ├── CLAUDE.md              # the constitution — single source of truth
    ├── skills/                # /claud-it:* slash commands
    ├── agents/                # the review panel
    ├── hooks/                 # mechanical gates
    └── settings/              # hook wiring template
```

The [constitution](./plugins/claud-it/CLAUDE.md) is the authoritative rulebook — scope tiers, escalation triggers, model assignment, findings vocabulary, and code conventions all live there. Every skill, agent, and hook defers to it.
