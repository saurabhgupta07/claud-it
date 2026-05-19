#!/usr/bin/env bash
# common.sh — shared helpers for claud-it hooks.
# Source this from each hook with: . "$(dirname "$0")/lib/common.sh"

# ---------- Fail-closed dependency checks ----------

require_jq() {
  command -v jq >/dev/null 2>&1 || {
    echo "claud-it hook: 'jq' is required but not installed. Install jq or disable this hook." >&2
    exit 1
  }
}

# ---------- Bypass escape hatch ----------
# If the user sets CLAUD_IT_BYPASS=1, all claud-it hooks become no-ops.
# Use sparingly — meant for emergency recovery (e.g., scope file deleted by accident).

claud_it_bypass_check() {
  if [[ "${CLAUD_IT_BYPASS:-0}" == "1" ]]; then
    echo "claud-it hook: bypass set via CLAUD_IT_BYPASS=1; skipping." >&2
    exit 0
  fi
}

# ---------- Robust git subcommand matcher ----------
# Returns 0 if $1 is a shell command line that invokes `git <subcommand>` at any
# command boundary (start of line, after ;, &&, ||, or pipe). Does NOT match
# `git commit-tree`, `git log --grep="git commit"`, etc.

is_git_subcommand() {
  local cmd_line="$1"
  local subcommand="$2"
  # Match: optional shell separators, then `git`, whitespace, then subcommand,
  # then either whitespace, end-of-line, or shell separator.
  if [[ "$cmd_line" =~ (^|[[:space:];&|]+)git[[:space:]]+${subcommand}([[:space:]]|$|[;&|]) ]]; then
    return 0
  fi
  return 1
}

# ---------- Extract the bash command from Claude Code's stdin JSON ----------

extract_tool_command() {
  local tool_input="$1"
  printf '%s' "$tool_input" | jq -r '.tool_input.command // empty'
}

# ---------- Cross-platform SHA256 ----------

sha256_stdin() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum | awk '{print $1}'
  else
    shasum -a 256 | awk '{print $1}'
  fi
}

# ---------- Hash for review marker (must match /claud-it:review-pr) ----------

hash_review_diff() {
  # Matches /claud-it:review-pr's hash: SHA256 over `git diff HEAD`, LF-normalized.
  git diff HEAD | tr -d '\r' | sha256_stdin
}
