#!/usr/bin/env bash
# pre-push-confirm-main.sh
#
# Warn on push to main/master/trunk/develop; block force-pushes to those branches.
# Wired via PreToolUse on Bash. Only acts when the command is `git push`.
#
# Exit codes:
#   0  - allow push
#   1  - block push (stderr explains why)
#
# Bypass: set CLAUD_IT_BYPASS=1 for emergency recovery.

set -uo pipefail

. "$(dirname "$0")/lib/common.sh"

# ---------- Preflight ----------

claud_it_bypass_check
require_jq

# ---------- Input ----------

TOOL_INPUT=$(cat)
COMMAND=$(extract_tool_command "$TOOL_INPUT")

is_git_subcommand "$COMMAND" "push" || exit 0

# ---------- Setup ----------

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$PROJECT_ROOT"

BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0

case "$BRANCH" in
  main|master|trunk|develop) ;;
  *) exit 0 ;;
esac

# ---------- Force-push detection (token-level) ----------
# Walk the command tokens. Allow --force-with-lease (safe); block --force / -f.

FORCE=0
# Use bash word splitting on the command (the JSON value is a single string)
read -ra TOKENS <<< "$COMMAND"
for tok in "${TOKENS[@]}"; do
  case "$tok" in
    --force-with-lease|--force-with-lease=*) ;;  # safe, allowed
    --force|-f) FORCE=1 ;;
  esac
done

if (( FORCE )); then
  echo "BLOCKED: force-push to ${BRANCH} refused." >&2
  echo "If absolutely intended, run the push directly in a terminal outside Claude Code." >&2
  echo "(Emergency bypass: CLAUD_IT_BYPASS=1)" >&2
  exit 1
fi

# ---------- Normal push to a protected branch: warn and allow ----------

echo "Note: pushing to ${BRANCH}. Make sure this is intended." >&2
exit 0
