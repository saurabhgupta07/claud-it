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

## 2. Merge into ~/.claude/settings.json

Use Python (more portable than jq for nested merges). Run:

```bash
python3 <<PYEOF
import json, os, sys
from pathlib import Path

CLAUD_IT_ROOT = "<resolved path from step 1>"
settings_path = Path.home() / ".claude" / "settings.json"

# Load or initialize
if settings_path.exists():
    data = json.loads(settings_path.read_text())
else:
    settings_path.parent.mkdir(parents=True, exist_ok=True)
    data = {}

# --- Hooks: append only if path not already present ---
# Schema: each PreToolUse entry is {matcher, hooks: [{type, command}, ...]}.
data.setdefault("hooks", {}).setdefault("PreToolUse", [])

hooks_to_add = [
    f"{CLAUD_IT_ROOT}/plugins/claud-it/hooks/pre-commit-checks.sh",
    f"{CLAUD_IT_ROOT}/plugins/claud-it/hooks/block-without-review.sh",
    f"{CLAUD_IT_ROOT}/plugins/claud-it/hooks/pre-push-confirm-main.sh",
]
our_cmd_set = set(hooks_to_add)

# Heal entries written by older buggy versions of this skill: those used
# {matcher, command} at the top level instead of nesting under "hooks".
# Only rewrite entries whose command matches one of our known hook paths.
healed = []
existing_cmds = set()
for entry in data["hooks"]["PreToolUse"]:
    if not isinstance(entry, dict):
        continue
    legacy_cmd = entry.get("command")
    if legacy_cmd in our_cmd_set and "hooks" not in entry:
        entry["hooks"] = [{"type": "command", "command": legacy_cmd}]
        del entry["command"]
        healed.append(os.path.basename(legacy_cmd))
    for h in entry.get("hooks", []) or []:
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
        "command": "scope=$(cat .claude/scope 2>/dev/null || echo 'unset — run /claud-it:scope'); echo \"🎯 scope: $scope\""
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

## 3. Confirm

If the Python block printed successfully, the merge is done. Tell the user to run `/reload-plugins` or restart Claude Code to pick up the new hooks.

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

- Hook entries with the same command path are never duplicated.
- Entries written by older buggy versions of this skill (top-level `command` instead of nested under `hooks`) are auto-healed in place, but only for the three claud-it hook paths — unrelated entries are not touched.
- An existing `statusLine` is never overwritten — only set if absent.
- No other settings keys are touched.

# Never

- Overwrite the user's existing `statusLine` configuration.
- Modify settings keys other than `hooks.PreToolUse` and `statusLine`.
- Use relative paths in hook commands — always absolute, resolved from `CLAUD_IT_ROOT`.
- Continue past a failed step. Stop and report.
