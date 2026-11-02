#!/usr/bin/env bash
# Claude Code PostToolUse hook: format a file right after Claude edits it.
# Receives the tool call as JSON on stdin; picks a formatter by extension and
# silently skips when the formatter is not installed. Never fails the tool call.
set -o nounset

has() { command -v "$1" >/dev/null 2>&1; }

# Extract .tool_input.file_path with jq, falling back to python3 (macOS has no jq).
read_file_path() {
  if has jq; then jq -r '.tool_input.file_path // empty'
  elif has python3; then python3 -c 'import json,sys; print((json.load(sys.stdin).get("tool_input") or {}).get("file_path") or "")'
  fi
}

file="$(read_file_path 2>/dev/null)"
[[ -n "$file" && -f "$file" ]] || exit 0

case "$file" in
  *.js|*.jsx|*.ts|*.tsx|*.json|*.css|*.scss|*.md|*.yaml|*.yml|*.html|*.vue)
    if has prettier; then prettier --log-level silent --write "$file"
    elif has npx && [[ -f package.json ]]; then npx --no-install prettier --log-level silent --write "$file" 2>/dev/null
    fi ;;
  *.py)
    if has ruff; then ruff format --quiet "$file"; ruff check --quiet --fix "$file"
    elif has uv; then uv run --quiet ruff format --quiet "$file" 2>/dev/null
    fi ;;
  *.go)   has gofmt   && gofmt -w "$file" ;;
  *.rs)   has rustfmt && rustfmt --quiet "$file" ;;
  *.sh|*.bash)
    has shfmt && shfmt -w -i 2 -ci "$file" ;;
  *.tf)   has terraform && terraform fmt "$file" >/dev/null ;;
esac
exit 0
