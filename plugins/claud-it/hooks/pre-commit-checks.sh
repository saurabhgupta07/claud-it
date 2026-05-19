#!/usr/bin/env bash
# pre-commit-checks.sh
#
# Mechanical pre-commit gate: secret-pattern scan, typecheck, lint.
# Wired via PreToolUse on Bash. Only acts when the command is `git commit`.
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
  echo "pre-commit-checks: not in a git repo; skipping." >&2
  exit 0
}
cd "$PROJECT_ROOT"

FAILED=()
FAILED_OUTPUT=()

# ---------- Secret scan on staged content ----------

SECRET_PATTERNS=(
  'AKIA[0-9A-Z]{16}'                                     # AWS Access Key ID
  '-----BEGIN (RSA |EC |DSA |OPENSSH |)?PRIVATE KEY-----' # PEM private keys
  'ghp_[A-Za-z0-9]{36,}'                                 # GitHub PAT (classic)
  'gho_[A-Za-z0-9]{36,}'                                 # GitHub OAuth
  'ghu_[A-Za-z0-9]{36,}'                                 # GitHub user-to-server
  'ghs_[A-Za-z0-9]{36,}'                                 # GitHub server-to-server
  'ghr_[A-Za-z0-9]{36,}'                                 # GitHub refresh
  'xox[baprs]-[A-Za-z0-9-]+'                             # Slack tokens
  'sk-[A-Za-z0-9]{32,}'                                  # OpenAI / Anthropic-style
  'sk_(live|test)_[A-Za-z0-9]{20,}'                      # Stripe live/test
)

SECRET_HITS=""
for pattern in "${SECRET_PATTERNS[@]}"; do
  hit=$(git diff --staged | grep -E "^\+.*${pattern}" || true)
  if [[ -n "$hit" ]]; then
    SECRET_HITS+="Pattern: ${pattern}"$'\n'"${hit}"$'\n\n'
  fi
done

if [[ -n "$SECRET_HITS" ]]; then
  echo "BLOCKED: pre-commit-checks detected a secret-shaped value in staged changes:" >&2
  echo "$SECRET_HITS" >&2
  echo "Move the secret to SSM/env/secret-manager and reference at runtime." >&2
  exit 1
fi

# ---------- Typecheck + lint (per project, best-effort) ----------

run_check() {
  local name="$1"; shift
  local output
  if output=$("$@" 2>&1); then
    return 0
  else
    FAILED+=("$name")
    # Capture the last 20 lines so the user sees something actionable
    FAILED_OUTPUT+=("--- $name ---"$'\n'"$(echo "$output" | tail -n 20)")
    return 1
  fi
}

if [[ -f package.json ]]; then
  jq -e '.scripts.typecheck' package.json >/dev/null 2>&1 && run_check "npm run typecheck" npm run typecheck
  jq -e '.scripts.lint'      package.json >/dev/null 2>&1 && run_check "npm run lint"      npm run lint
fi

if [[ -f pyproject.toml || -f setup.py ]]; then
  command -v ruff >/dev/null 2>&1 && run_check "ruff check" ruff check .
  command -v mypy >/dev/null 2>&1 && run_check "mypy"       mypy .
fi

if [[ ${#FAILED[@]} -gt 0 ]]; then
  echo "BLOCKED: pre-commit-checks failed:" >&2
  for f in "${FAILED[@]}"; do echo "  - $f" >&2; done
  echo "" >&2
  for out in "${FAILED_OUTPUT[@]}"; do echo "$out" >&2; echo "" >&2; done
  echo "Fix the issues above and retry the commit." >&2
  exit 1
fi

exit 0
