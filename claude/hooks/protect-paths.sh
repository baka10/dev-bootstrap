#!/usr/bin/env bash
# Claude Code PreToolUse hook: refuse edits to files that must never be
# touched by an assistant (secrets, keys, lock files written by tools).
# Exit 2 blocks the tool call and feeds the message back to Claude.
set -o nounset

has() { command -v "$1" >/dev/null 2>&1; }

read_file_path() {
  if has jq; then jq -r '.tool_input.file_path // empty'
  elif has python3; then python3 -c 'import json,sys; print((json.load(sys.stdin).get("tool_input") or {}).get("file_path") or "")'
  fi
}

file="$(read_file_path 2>/dev/null)"
[[ -n "$file" ]] || exit 0
base="$(basename "$file")"

case "$base" in
  .env.example|.env.sample|.env.template|.env.dist)
    exit 0 ;;   # templates hold no secrets
  .env|.env.*|*.pem|*.key|id_rsa*|id_ed25519*|credentials.json|.credentials.json|.npmrc|.pypirc)
    echo "Blocked: '$file' holds secrets. Ask the user to edit it by hand." >&2
    exit 2 ;;
  package-lock.json|pnpm-lock.yaml|yarn.lock|uv.lock|poetry.lock|Cargo.lock|go.sum)
    echo "Blocked: '$file' is a lock file. Change the manifest and run the package manager instead." >&2
    exit 2 ;;
esac
exit 0
