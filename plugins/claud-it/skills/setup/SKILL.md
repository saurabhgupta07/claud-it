---
name: setup
description: One-time post-install setup. Wires claud-it hooks and status line into the user's Claude Code settings. Idempotent — safe to re-run.
---

# Role

You are the claud-it setup utility. Run once after `/plugin install claud-it@claud-it`. Your job is to merge the hooks configuration and the status line into `~/.claude/settings.json` so the user doesn't have to edit JSON by hand. Running this twice or more must be safe.

# Action

Execute these steps in order. If any step fails, stop and report to the user — do not proceed with later steps.

## 1. Resolve CLAUD_IT_ROOT

Run:

```bash
ls -d ~/.claude/plugins/cache/claud-it/claud-it/*/ 2>/dev/null | sort -V | tail -1
```

This returns the latest installed version directory. Strip the trailing slash and use that path as `CLAUD_IT_ROOT`. If empty, stop and tell the user: "claud-it plugin folder not found. Verify with `/plugin install claud-it@claud-it --scope user`."

## 2. Create stable hook wrappers

The actual hook scripts live inside the versioned plugin cache directory, which changes on every `/plugin update`. To avoid `settings.json` going stale after each update, create **stable wrapper scripts** at a version-independent path. Each wrapper self-resolves to the currently installed version at call time.

Run:

```bash
python3 <<PYEOF
import os, stat
from pathlib import Path

WRAPPER_DIR = Path.home() / ".claude" / "claud-it" / "hooks"
WRAPPER_DIR.mkdir(parents=True, exist_ok=True)

WRAPPER_BODY = '''\
#!/bin/bash
# Stable wrapper — resolves to the currently installed claud-it version.
# settings.json registers this path; it never needs updating after /plugin update.
ROOT=$(ls -d "$HOME/.claude/plugins/cache/claud-it/claud-it/"*/ 2>/dev/null | sort -V | tail -1)
ROOT="${ROOT%/}"
if [ -z "$ROOT" ]; then
  printf \'{"continue":true}\'
  exit 0
fi
exec "$ROOT/hooks/$(basename "$0")" "$@"
'''

HOOK_NAMES = [
    "pre-commit-checks.sh",
    "block-without-review.sh",
    "pre-push-confirm-main.sh",
]

created = []
for name in HOOK_NAMES:
    p = WRAPPER_DIR / name
    p.write_text(WRAPPER_BODY)
    p.chmod(p.stat().st_mode | stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)
    created.append(str(p))

print("Wrappers written:")
for c in created:
    print(f"  {c}")
PYEOF
```

## 3. Merge into ~/.claude/settings.json

Use Python (more portable than jq for nested merges). Run:

```bash
python3 <<PYEOF
import json, os, sys
from pathlib import Path

CLAUD_IT_ROOT = "<resolved path from step 1>"
WRAPPER_DIR = str(Path.home() / ".claude" / "claud-it" / "hooks")
settings_path = Path.home() / ".claude" / "settings.json"

# Load or initialize
if settings_path.exists():
    data = json.loads(settings_path.read_text())
else:
    settings_path.parent.mkdir(parents=True, exist_ok=True)
    data = {}

# --- Hooks: register stable wrappers, not versioned paths ---
# Schema: each PreToolUse entry is {matcher, hooks: [{type, command}, ...]}.
data.setdefault("hooks", {}).setdefault("PreToolUse", [])

HOOK_NAMES = [
    "pre-commit-checks.sh",
    "block-without-review.sh",
    "pre-push-confirm-main.sh",
]

# Stable wrapper paths — never change across plugin updates
hooks_to_add = [f"{WRAPPER_DIR}/{name}" for name in HOOK_NAMES]
our_cmd_set = set(hooks_to_add)

# Paths written by older buggy versions of this skill (versioned or with
# extra "plugins/claud-it/" segment). Map them to the correct stable path.
legacy_patterns = []
for cache_entry in Path.home().glob(".claude/plugins/cache/claud-it/claud-it/*/"):
    for name in HOOK_NAMES:
        versioned = str(cache_entry / "hooks" / name)
        buggy = str(cache_entry / "plugins" / "claud-it" / "hooks" / name)
        correct = f"{WRAPPER_DIR}/{name}"
        legacy_patterns.append((versioned, correct))
        legacy_patterns.append((buggy, correct))
old_to_new = dict(legacy_patterns)

# Heal legacy entries, collect existing stable-path commands
healed = []
existing_cmds = set()
for entry in data["hooks"]["PreToolUse"]:
    if not isinstance(entry, dict):
        continue
    # Heal: legacy schema — top-level command instead of nested under hooks
    legacy_cmd = entry.get("command")
    if legacy_cmd in our_cmd_set and "hooks" not in entry:
        entry["hooks"] = [{"type": "command", "command": legacy_cmd}]
        del entry["command"]
        healed.append(os.path.basename(legacy_cmd) + " (schema fix)")
    # Heal: versioned or buggy-path entries → stable wrapper path
    for h in entry.get("hooks", []) or []:
        if isinstance(h, dict) and h.get("command") in old_to_new:
            correct = old_to_new[h["command"]]
            h["command"] = correct
            healed.append(os.path.basename(correct) + " (path → stable wrapper)")
        if isinstance(h, dict) and h.get("command"):
            existing_cmds.add(h["command"])

added_hooks = []
for cmd in hooks_to_add:
    if cmd not in existing_cmds:
        data["hooks"]["PreToolUse"].append({
            "matcher": "Bash",
            "hooks": [{"type": "command", "command": cmd}],
        })
        added_hooks.append(os.path.basename(cmd))

# --- Status line: only set if absent (never overwrite user's) ---
status_action = "set"
if "statusLine" not in data:
    data["statusLine"] = {
        "type": "command",
        "command": "input=$(cat); session_id=$(echo \"$input\" | jq -r '.session_id'); scope_file=\"$HOME/.claude/scopes/$session_id\"; if [ -f \"$scope_file\" ]; then tier=$(head -n 1 \"$scope_file\" | tr -d '[:space:]'); else tier='∅ no scope'; fi; echo \"🎯 $tier\""
    }
else:
    status_action = "preserved existing"

# Write back
settings_path.write_text(json.dumps(data, indent=2) + "\n")

# Report
print(f"✓ claud-it setup complete")
print(f"  CLAUD_IT_ROOT: {CLAUD_IT_ROOT}")
if added_hooks:
    print(f"  Hooks added: {', '.join(added_hooks)}")
else:
    print(f"  Hooks: already present (no changes)")
if healed:
    print(f"  Hooks healed (schema fix): {', '.join(healed)}")
print(f"  Status line: {status_action}")
print()
print("Restart Claude Code or run /reload-plugins to activate.")
PYEOF
```

## 4. Confirm

If both Python blocks printed successfully, the merge is done. Tell the user to run `/reload-plugins` or restart Claude Code to pick up the new hooks.

If the user already has a custom `statusLine`, the existing one was preserved. Show them the claud-it config they can manually substitute if they want the scope display:

```json
{
  "statusLine": {
    "type": "command",
    "command": "scope=$(cat .claude/scope 2>/dev/null || echo 'unset — run /claud-it:scope'); echo \"🎯 scope: $scope\""
  }
}
```

# Idempotency

This skill is safe to run any number of times:

- Stable wrapper scripts are overwritten with identical content — no harm.
- Hook entries pointing to the stable wrappers are never duplicated.
- Entries written by older versions of this skill are auto-healed in place:
  - *Schema bug* — top-level `command` instead of nested under `hooks` — fixed by restructuring the entry.
  - *Versioned-path bug* — pointing directly at a versioned cache dir (breaks on `/plugin update`) — rewritten to the stable wrapper path.
  - *Double-segment bug* — extra `plugins/claud-it/` between `CLAUD_IT_ROOT` and `hooks/` — also rewritten to stable wrapper.
  - Only the three claud-it hook paths are touched; unrelated entries are never modified.
- An existing `statusLine` is never overwritten — only set if absent.
- No other settings keys are touched.

# Never

- Overwrite the user's existing `statusLine` configuration.
- Modify settings keys other than `hooks.PreToolUse` and `statusLine`.
- Use relative paths in hook commands — always absolute, resolved from `CLAUD_IT_ROOT`.
- Continue past a failed step. Stop and report.
