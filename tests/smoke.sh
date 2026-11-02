#!/usr/bin/env bash
# Smoke tests that touch nothing on the host:
#   * every module loads and runs under --dry-run
#   * configuration (bootstrap.conf, --ai, env) is honoured
#   * the library helpers behave (symlink + backup, json merge, idempotence)
#   * the Claude Code hooks block / allow the right files
set -o errexit -o nounset -o pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
REPO_ROOT="$PWD"
export NO_COLOR=1
LOG="$(mktemp)"

pass=0; fail=0
ok()    { pass=$((pass + 1)); echo "  ok   $1"; }
nok()   { fail=$((fail + 1)); echo "  FAIL $1"; }
check() { if "$2" >"$LOG" 2>&1; then ok "$1"; else nok "$1"; sed 's/^/       | /' "$LOG" | tail -5; fi; }
# Capture full output before grepping: `installer | grep -q` would SIGPIPE the
# installer on the first match and make a passing run look like a failure.
dry()      { ./install.sh --dry-run --yes "$@" 2>&1; }
dry_has()  { local pat="$1" out; shift; out="$(dry "$@")"; grep -q -- "$pat" <<<"$out"; }
dry_lacks(){ ! dry_has "$@"; }
dry_count(){ local pat="$1" out; shift; out="$(dry "$@")"; grep -c -- "$pat" <<<"$out"; }

echo "== installer"
t_help()   { local out; out="$(./install.sh --help)"; grep -q -- '--dry-run' <<<"$out"; }
t_list()   { local out; out="$(./install.sh --list)"; grep -q 'claude-code' <<<"$out" && grep -q 'copilot' <<<"$out"; }
t_dry()    {
  if ! dry > "$LOG.dry"; then tail -8 "$LOG.dry"; return 1; fi
  grep -q 'dry run: nothing was changed' "$LOG.dry" && grep -q 'module: copilot' "$LOG.dry"
}
t_only()   { dry_has 'module: dotfiles' --only dotfiles && dry_lacks 'module: zsh' --only dotfiles; }
t_skip()   { dry_lacks 'module: fonts' --skip fonts,claude-code; }
t_badopt() { ! ./install.sh --nope >/dev/null 2>&1; }
t_badmod() { ! ./install.sh --dry-run --yes --only dotfile >/dev/null 2>&1 && ! ./install.sh --dry-run --yes --skip zshh >/dev/null 2>&1; }
check "--help prints usage"             t_help
check "--list shows modules"            t_list
check "--dry-run runs every module"     t_dry
check "--only limits modules"           t_only
check "--skip excludes modules"         t_skip
check "unknown option fails"            t_badopt
check "unknown module name fails"       t_badmod

echo "== configuration"
t_ai_default() { dry_has 'ai=claude' --only copilot && dry_has 'skipping GitHub Copilot' --only copilot; }
t_ai_flag()    { dry_has 'skipping Claude Code' --ai copilot --only claude-code; }
t_ai_env()     { [[ "$(AI_ASSISTANT=none dry_count 'skipping' --only claude-code,copilot)" == 2 ]]; }
t_ai_both()    { dry_lacks 'skipping Claude Code' --ai both --only claude-code && dry_lacks 'skipping GitHub Copilot' --ai both --only copilot; }
t_ai_bad()     { ! ./install.sh --dry-run --yes --ai vim >/dev/null 2>&1; }
t_local_conf() {
  # Never touch a real bootstrap.local.conf: run against a copy of the repo.
  local tmp; tmp="$(mktemp -d)"
  cp -R "$REPO_ROOT"/. "$tmp"/
  printf 'AI_ASSISTANT=copilot\n' > "$tmp/bootstrap.local.conf"
  local out; out="$("$tmp/install.sh" --dry-run --yes --only claude-code 2>&1)"
  rm -rf "$tmp"
  grep -q 'ai=copilot' <<<"$out"
}
check "AI_ASSISTANT defaults to claude"  t_ai_default
check "--ai flag overrides config"       t_ai_flag
check "AI_ASSISTANT env overrides config" t_ai_env
check "--ai both runs both modules"      t_ai_both
check "invalid --ai value fails"         t_ai_bad
check "bootstrap.local.conf overrides"   t_local_conf

echo "== library (in a throwaway HOME)"
TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME" "$LOG" "$LOG.dry"' EXIT
run_lib() {
  HOME="$TMP_HOME" BACKUP_DIR="$TMP_HOME/.backup" DRY_RUN=0 \
    bash -c "source '$REPO_ROOT/lib/common.sh'; $1"
}
t_link_new() {
  run_lib "link_file '$REPO_ROOT/dotfiles/zshrc' \"\$HOME/.zshrc\""
  [[ "$(readlink "$TMP_HOME/.zshrc")" == "$REPO_ROOT/dotfiles/zshrc" ]]
}
t_link_backup() {
  echo old > "$TMP_HOME/.gitconfig"
  run_lib "link_file '$REPO_ROOT/dotfiles/gitconfig' \"\$HOME/.gitconfig\""
  [[ -L "$TMP_HOME/.gitconfig" && "$(cat "$TMP_HOME/.backup/.gitconfig")" == old ]]
}
t_link_idem() {
  local out; out="$(run_lib "link_file '$REPO_ROOT/dotfiles/zshrc' \"\$HOME/.zshrc\"")"
  grep -q 'already done' <<<"$out"
}
t_copy_once() {
  run_lib "copy_if_missing '$REPO_ROOT/dotfiles/zshrc.local.example' \"\$HOME/.zshrc.local\""
  echo mine > "$TMP_HOME/.zshrc.local"
  run_lib "copy_if_missing '$REPO_ROOT/dotfiles/zshrc.local.example' \"\$HOME/.zshrc.local\""
  [[ "$(cat "$TMP_HOME/.zshrc.local")" == mine ]]
}
# Assertions on JSON use python3 so the test runs where jq is absent (macOS).
json_has() { python3 -c '
import json,sys
d=json.load(open(sys.argv[1])); ok=True
ok &= d["model"]=="opus"
ok &= "Bash(mine *)" in d["permissions"]["allow"]
ok &= d["enabledPlugins"]["superpowers@claude-plugins-official"] is True
# the stale hook group with the same matcher is replaced, not duplicated
ok &= len(d["hooks"]["PostToolUse"])==1
ok &= "old-hook" not in json.dumps(d["hooks"]["PostToolUse"])
sys.exit(0 if ok else 1)' "$1"; }
t_json_merge() {
  echo '{"model":"opus","permissions":{"allow":["Bash(ls *)","Bash(mine *)"]},"hooks":{"PostToolUse":[{"matcher":"Edit|Write|MultiEdit","hooks":[{"type":"command","command":"old-hook"}]}]}}' > "$TMP_HOME/base.json"
  run_lib "json_merge \"\$HOME/base.json\" '$REPO_ROOT/claude/settings.json'" > "$TMP_HOME/merged.json"
  json_has "$TMP_HOME/merged.json"
}
t_json_merge_jq() {
  # The jq path is only exercised where jq exists; the test fails loudly when it
  # exists and misbehaves, and is skipped otherwise.
  command -v jq >/dev/null 2>&1 || { echo "  (jq not installed, skipped)"; return 0; }
  jq -n '{}' >/dev/null
  run_lib "json_merge \"\$HOME/base.json\" '$REPO_ROOT/claude/settings.json'" > "$TMP_HOME/merged-jq.json"
  json_has "$TMP_HOME/merged-jq.json"
}
t_json_merge_py() {
  # Force the python3 path even when jq is installed.
  run_lib "has() { [[ \$1 != jq ]] && command -v \"\$1\" >/dev/null 2>&1; }; json_merge \"\$HOME/base.json\" '$REPO_ROOT/claude/settings.json'" > "$TMP_HOME/merged-py.json"
  json_has "$TMP_HOME/merged-py.json"
}
# shellcheck disable=SC2016  # the quoted snippet is evaluated by run_lib
t_detect_os()      { run_lib 'detect_os; [[ "$OS" == linux || "$OS" == macos ]] && [[ -n "$PKG" ]]'; }
t_settings_json()  { python3 -c 'import json,sys; json.load(open(sys.argv[1]))' claude/settings.json && python3 -c 'import json,sys; json.load(open(sys.argv[1]))' copilot/config.json; }
check "link_file creates symlink"        t_link_new
check "link_file backs up old file"      t_link_backup
check "link_file is idempotent"          t_link_idem
check "copy_if_missing never overwrites" t_copy_once
check "json_merge keeps user keys"       t_json_merge
check "json_merge jq path"               t_json_merge_jq
check "json_merge python3 fallback"      t_json_merge_py
check "detect_os works here"             t_detect_os
check "settings/config JSON is valid"    t_settings_json

echo "== hooks"
t_protect_blocks() { ! echo '{"tool_input":{"file_path":"/x/.env"}}' | bash claude/hooks/protect-paths.sh 2>/dev/null; }
t_protect_lock()   { ! echo '{"tool_input":{"file_path":"/x/package-lock.json"}}' | bash claude/hooks/protect-paths.sh 2>/dev/null; }
t_protect_allows() { echo '{"tool_input":{"file_path":"/x/main.py"}}' | bash claude/hooks/protect-paths.sh; }
t_protect_example() { echo '{"tool_input":{"file_path":"/x/.env.example"}}' | bash claude/hooks/protect-paths.sh; }
t_format_no_prettier() {
  # A YAML file in a project without prettier config must be left untouched.
  local d; d="$(mktemp -d)"; printf 'a:   1\n' > "$d/x.yaml"
  echo "{\"tool_input\":{\"file_path\":\"$d/x.yaml\"}}" | bash claude/hooks/format-on-edit.sh
  [[ "$(cat "$d/x.yaml")" == 'a:   1' ]]; local rc=$?; rm -rf "$d"; return $rc
}
t_format_noop()    { echo '{"tool_input":{"file_path":"/nonexistent/file.py"}}' | bash claude/hooks/format-on-edit.sh; }
t_format_badjson() { echo 'not json' | bash claude/hooks/format-on-edit.sh; }
check "protect-paths blocks .env"        t_protect_blocks
check "protect-paths blocks lock files"  t_protect_lock
check "protect-paths allows code"        t_protect_allows
check "protect-paths allows .env.example" t_protect_example
check "format-on-edit skips non-prettier projects" t_format_no_prettier
check "format-on-edit tolerates missing file" t_format_noop
check "format-on-edit tolerates bad input"    t_format_badjson

echo
echo "passed: $pass  failed: $fail"
[[ "$fail" -eq 0 ]]
