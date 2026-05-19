# claud-it

A Claude Code plugin that turns Claude into a disciplined SDLC team — PM, designer, TPM, and a panel of reviewers — shipping every change through the right amount of ceremony.

claud-it works in **scope tiers** (`experiment` / `patch` / `feature` / `system`). Either you set the tier explicitly, or claud-it classifies your diff and picks one. Either way, the tier governs which skills, agents, and hooks fire. Tiny tweak? Just a review panel. New feature? Walks you from requirements through design, plan, implement, review, ship — with specialist agents reviewing in parallel at each stage.

## Setup (one-time)

Three commands. Run once, claud-it is active in every project on your machine.

```
/plugin marketplace add saurabhgupta07/claud-it
/plugin install claud-it@claud-it --scope user
/reload-plugins
/claud-it:setup
```

`--scope user` makes claud-it available across all projects. After `/reload-plugins`, the **dispatcher** becomes your default Claude agent — it triages every message and routes work-intent through the right workflow without you invoking anything. `/claud-it:setup` wires the hooks and status line into your `~/.claude/settings.json` automatically; you don't need to edit JSON by hand.

You're done. Open Claude Code in any project. The dispatcher engages automatically.

## Usage

Every change starts the same way: set or detect a scope.

```
/claud-it:scope           # Claude classifies your diff for you
/claud-it:scope feature   # or pick the tier explicitly
```

| Tier | When to use | Workflow |
| --- | --- | --- |
| `experiment` | Throwaway code, spike, prototype | None. Skills run only when invoked. |
| `patch` | Bug fix, small refactor, copy change (1–5 files) | `/claud-it:review-pr` |
| `feature` | New user-visible behavior (3–15 files, multi-PR) | requirements → design → plan → implement → review-pr → ship |
| `system` | New subsystem, breaking change (10+ files) | feature workflow + `principal-ux` when UI is involved |

**Auto-escalation**: touching auth, secrets, migrations, IAM, billing, or infra forces tier ≥ `feature` (two triggers → `system`). Full rules in [`plugins/claud-it/CLAUDE.md`](plugins/claud-it/CLAUDE.md).

### Typical feature flow

```
/claud-it:scope feature
/claud-it:requirements "users can set reminders"   # → docs/prd/reminders.md
/claud-it:design                                   # → docs/design/reminders.md
/claud-it:plan                                     # → plans/reminders.md
# implement task 1
/claud-it:review-pr                                # before each commit
# ... continue per plan task ...
/claud-it:ship                                     # final gate
```

For a `patch`, this collapses to: edit → `/claud-it:review-pr` → commit.

## Skills

| Command | What it does |
| --- | --- |
| `/claud-it:setup` | One-time post-install. Merges hooks and status line into `~/.claude/settings.json`. Idempotent. |
| `/claud-it:scope [tier]` | Classify the diff and write `.claude/scope`. Run this first on every change. |
| `/claud-it:requirements "<idea>"` | PM interviews you and writes `docs/prd/<slug>.md`. |
| `/claud-it:design` | Lead engineer drafts a design from the PRD, then `staff-engineer` + `security-engineer` (+ `principal-ux` if UI) critique in parallel until approved. Writes `docs/design/<slug>.md`. |
| `/claud-it:plan` | Decomposes the design into PR-sized tasks. `staff-tpm` reviews sequencing/risk. Writes `plans/<slug>.md` (gitignored). |
| `/claud-it:review-pr` | The workhorse. Spawns `code-reviewer` + `code-quality-reviewer` + `security-engineer` in parallel against the current diff, synthesizes findings, writes a review marker. The pre-commit hook reads this marker. |
| `/claud-it:ship` | Final gate. Verifies all artifacts are confirmed, then `integ-test-author` generates integration tests. |

## Agents

The dispatcher routes; specialists review. You invoke skills, not agents directly.

| Agent | Model | Role |
| --- | --- | --- |
| `dispatcher` | Sonnet | Triages every user message, routes to scope-appropriate workflow. Default main-thread agent. |
| `staff-engineer` | Opus | Architecture & design review |
| `security-engineer` | Opus | Auth, secrets, IAM, injection, supply chain |
| `principal-ux` | Opus | UI/UX flows, copy, accessibility (UI only) |
| `staff-tpm` | Sonnet | Task sequencing, dependencies, risk ordering |
| `code-reviewer` | Sonnet | Per-PR bug & logic review |
| `code-quality-reviewer` | Sonnet | DRY, naming, maintainability, type tightness |
| `integ-test-author` | Sonnet | Generates integration tests at ship time |

Each review agent runs in a fresh context — reviewers can't see the writer's reasoning, so they can't be biased into approval. Findings come back as `BLOCKER` / `WARNING` / `SUGGESTION` with file:line and recommended fix.

## Hooks

Wired automatically by `/claud-it:setup`. Fire on shell events, not Claude's discretion.

| Hook | Trigger | Behavior |
| --- | --- | --- |
| `pre-commit-checks.sh` | `git commit` | Secret-pattern scan, typecheck, lint. Blocks commit on failure. |
| `block-without-review.sh` | `git commit` | Refuses commit unless `/claud-it:review-pr` ran on current diff (matched by hash). |
| `pre-push-confirm-main.sh` | `git push` | Warns on push to main/master/trunk/develop. Blocks force-pushes. |

All honor `CLAUD_IT_BYPASS=1` as emergency escape.

## Artifacts

claud-it produces durable artifacts in the **consumer project** (not this repo):

- **Committed**: `docs/prd/<feature>.md`, `docs/design/<feature>.md`, `docs/adr/NNNN-<title>.md`, `docs/ux/<feature>.md`
- **Gitignored**: `plans/<feature>.md`, `.claude/scope`, `.claude/last-review`

## Project structure

```
claud-it/
├── README.md
├── .claude-plugin/marketplace.json
└── plugins/claud-it/
    ├── plugin.json
    ├── settings.json          # auto-loaded: activates the dispatcher
    ├── CLAUDE.md              # the constitution — rulebook for skills and agents
    ├── skills/                # /claud-it:* slash commands (including setup)
    ├── agents/                # dispatcher + the review panel
    ├── hooks/                 # mechanical gates (git commit/push)
    └── settings/
        └── settings.json.template   # reference only — /claud-it:setup does the merge
```

The [constitution](plugins/claud-it/CLAUDE.md) defines scope tiers, escalation triggers, model assignment, findings vocabulary, and code conventions.
