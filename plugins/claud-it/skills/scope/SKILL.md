---
name: scope
description: Classify the current diff into a scope tier and write it to ~/.claude/scopes/$CLAUDE_CODE_SESSION_ID. Tier definitions, auto-escalation rules, and override semantics live in CLAUDE.md. Run before any /claud-it workflow. Accepts optional <tier> arg to manually override.
---

# /claud-it:scope

Classify the current change and write the scope tier marker. Other workflows read the marker this writes. **Tier definitions, auto-escalation rules, and override semantics are defined in `plugins/claud-it/CLAUDE.md` — defer to it.**

## `/claud-it:scope` (no args)

1. Run `git diff HEAD` to see all current changes (staged + unstaged).
2. If working tree is clean: print "No changes — no tier to set." Stop.
3. **Compute heuristic tier** from file count and nature of change, per CLAUDE.md §Scope tiers:
   - 1–5 files, single concern → `patch`
   - 3–15 files, new user-visible behavior → `feature`
   - 10+ files, new subsystem or breaking change → `system`
   - Experiment signals (see below) → `experiment`
4. **Compute auto-escalation floor** from CLAUDE.md §Auto-escalation: scan diff for trigger areas (auth, secrets, migrations, IAM, billing, infra).
   - 0 triggers → no floor
   - 1 trigger → floor is `feature`
   - 2+ triggers → floor is `system`
5. **Final tier = max(heuristic tier, escalation floor).** When unsure between two tiers, pick the higher (per CLAUDE.md).
6. Write the tier using this exact shell command (replace `<tier>` with the computed value):
   ```bash
   mkdir -p "$HOME/.claude/scopes"
   printf '%s\n' "<tier>" > "$HOME/.claude/scopes/$CLAUDE_CODE_SESSION_ID"
   ```
7. Log loudly: `📋 Tier: <tier>. Reason: <one-line>. Override with /claud-it:scope <tier>.`

### Experiment signals

`experiment` is not picked from a diff alone — only set it when ALL changes show one of:
- Filenames containing `scratch`, `spike`, `playground`, or `experiment`
- Commit message starts with `WIP:` or `spike:`
- All changes confined to a `playground/` or `experiments/` directory

Otherwise prefer patch/feature/system.

## `/claud-it:scope <tier>` (manual override)

1. Validate the tier name against CLAUDE.md's defined tiers. If invalid, print valid options and stop.
2. **Compute what auto-escalation would require** for the current diff (per CLAUDE.md §Auto-escalation) so step 4 can name what's being bypassed.
3. Write the tier using this exact shell command:
   ```bash
   mkdir -p "$HOME/.claude/scopes"
   printf '%s\n' "<tier>" > "$HOME/.claude/scopes/$CLAUDE_CODE_SESSION_ID"
   ```
4. If the override is below the auto-escalation requirement, log:
   `⚠️ Override to <tier>. Diff touches <list-of-triggers> — auto-escalation requires <required-tier>. Proceeding with override.`
5. Otherwise log: `📋 Tier set to <tier> (user override).`

## Marker file format

Plain text at `~/.claude/scopes/$CLAUDE_CODE_SESSION_ID`.

- **Line 1:** the tier name (one of: `experiment`, `patch`, `feature`, `system`).

Example:
```
feature
```

Consumers (status bar, hooks, other skills) read line 1 only.

## Behavior

- Create `~/.claude/scopes/` if it doesn't exist.
- Overwrite the file if it already exists — it holds the *current* tier for this session.
- Exit non-zero on invalid tier or `git diff` failure; zero otherwise.

## What NOT to do

- Don't classify silently — always log the chosen tier and reason.
- Don't classify without reading the diff (unless user passed a tier explicitly).
- Don't refuse user overrides — warn and proceed.
- Don't write to `.claude/scope` or any project directory — session ID is the only key.
- If `git diff` fails (not a git repo), surface clearly and stop.
