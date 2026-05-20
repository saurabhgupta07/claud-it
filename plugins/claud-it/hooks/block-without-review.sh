#!/usr/bin/env bash
# block-without-review.sh
#
# Refuse `git commit` unless /claud-it:review-pr was run on the current diff.
# Wired via PreToolUse on Bash. Only acts when the command is `git commit`.
#
# Reads:
#   ~/.claude/scopes/$CLAUDE_CODE_SESSION_ID  — current tier (session-keyed)
#   <project-root>/.claude/last-review        — diff hash + blockers count
#
# Exit codes:
#   0  - allow commit
#   1  - block commit (stderr explains why)
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

is_git_subcommand "$COMMAND" "commit" || exit 0

# ---------- Setup ----------

PROJECT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "block-without-review: not in a git repo; skipping." >&2
  exit 0
}
cd "$PROJECT_ROOT"

SCOPE_FILE="$HOME/.claude/scopes/$CLAUDE_CODE_SESSION_ID"
REVIEW_FILE="$PROJECT_ROOT/.claude/last-review"

# ---------- Scope check ----------

if [[ ! -f "$SCOPE_FILE" ]]; then
  echo "BLOCKED: no scope set for this session." >&2
  echo "Run /claud-it:scope to classify this change before committing." >&2
  echo "(Emergency bypass: CLAUD_IT_BYPASS=1)" >&2
  exit 1
fi

SCOPE=$(head -n 1 "$SCOPE_FILE" | tr -d '[:space:]')

# experiment tier bypasses review entirely
case "$SCOPE" in
  experiment) exit 0 ;;
esac

# ---------- Review marker present ----------

if [[ ! -f "$REVIEW_FILE" ]]; then
  echo "BLOCKED: no /claud-it:review-pr marker found." >&2
  echo "Run /claud-it:review-pr before committing." >&2
  echo "(Emergency bypass: CLAUD_IT_BYPASS=1)" >&2
  exit 1
fi

# ---------- Hash freshness ----------

MARKER_HASH=$(head -n 1 "$REVIEW_FILE" | tr -d '[:space:]')
CURRENT_HASH=$(hash_review_diff)

if [[ "$MARKER_HASH" != "$CURRENT_HASH" ]]; then
  echo "BLOCKED: /claud-it:review-pr marker is stale." >&2
  echo "  marker hash:  $MARKER_HASH" >&2
  echo "  current diff: $CURRENT_HASH" >&2
  echo "Re-run /claud-it:review-pr against the current diff." >&2
  exit 1
fi

# ---------- Blocker count ----------

BLOCKERS=$(grep -E '^# blockers:' "$REVIEW_FILE" | head -n 1 | awk -F: '{print $2}' | tr -d '[:space:]')

if [[ ! "$BLOCKERS" =~ ^[0-9]+$ ]]; then
  echo "BLOCKED: review marker has non-numeric blocker count: '$BLOCKERS'." >&2
  echo "Re-run /claud-it:review-pr to produce a valid marker." >&2
  exit 1
fi

if (( BLOCKERS > 0 )); then
  echo "BLOCKED: latest review found ${BLOCKERS} BLOCKER(s)." >&2
  echo "Fix them, then re-run /claud-it:review-pr." >&2
  exit 1
fi

exit 0
