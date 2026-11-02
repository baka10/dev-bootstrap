#!/usr/bin/env bash
# Claude Code CLI + plugins (superpowers, caveman) + global CLAUDE.md, settings, hooks, skills
# shellcheck source=lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"
load_config
detect_os

if ! wants_ai claude; then
  log_info "AI_ASSISTANT=$AI_ASSISTANT: skipping Claude Code (set it to claude or both in bootstrap.conf)"
  exit 0
fi

C="$REPO_ROOT/claude"
CLAUDE_HOME="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
export PATH="$HOME/.local/bin:$PATH"

# --- CLI ----------------------------------------------------------------------
if has claude; then
  log_skip "claude $(claude --version 2>/dev/null | head -1)"
else
  log_info "installing Claude Code (native installer -> ~/.local/bin/claude)"
  if [[ "$DRY_RUN" == 1 ]]; then
    run echo "curl -fsSL https://claude.ai/install.sh | bash"
  else
    curl -fsSL --retry 3 https://claude.ai/install.sh | bash
  fi
  has claude || log_warn "claude not on PATH yet; open a new shell and re-run this module for plugins"
fi

# --- Global instructions, hooks, skills (symlinked so edits live in the repo) --
ensure_dir "$CLAUDE_HOME/hooks"
ensure_dir "$CLAUDE_HOME/skills"
link_file "$C/CLAUDE.md"                   "$CLAUDE_HOME/CLAUDE.md"
link_file "$C/hooks/format-on-edit.sh"     "$CLAUDE_HOME/hooks/format-on-edit.sh"
link_file "$C/hooks/protect-paths.sh"      "$CLAUDE_HOME/hooks/protect-paths.sh"
link_file "$C/skills/conventional-commit"  "$CLAUDE_HOME/skills/conventional-commit"

# --- settings.json: deep-merge so user-added keys survive ---------------------
has jq || has python3 || die "jq or python3 is required to merge settings.json"
settings="$CLAUDE_HOME/settings.json"
if [[ -f "$settings" ]]; then
  merged="$(json_merge "$settings" "$C/settings.json")"
  if [[ "$merged" == "$(json_pretty "$settings")" ]]; then
    log_skip "settings.json already contains the repo settings"
  else
    backup_path "$settings"
    if [[ "$DRY_RUN" == 1 ]]; then
      run echo "write merged $settings"
    else
      printf '%s\n' "$merged" > "$settings"
    fi
    log_ok "merged repo settings into $settings"
  fi
else
  ensure_dir "$CLAUDE_HOME"
  run cp "$C/settings.json" "$settings"
  log_ok "created $settings"
fi

# --- Plugins ------------------------------------------------------------------
if ! has claude; then
  log_warn "skipping plugin installation (claude not available)"
  exit 0
fi

# Capture the listing first: `claude ... | grep -q` would SIGPIPE claude on the
# first match and, under pipefail, report an installed plugin as missing.
marketplace_known() { local out; out="$(claude plugin marketplace list 2>/dev/null)"; grep -qF -- "$1" <<<"$out"; }
plugin_installed()  { local out; out="$(claude plugin list 2>/dev/null)"; grep -qF -- "$1" <<<"$out"; }

# caveman lives in its own marketplace; superpowers is in Anthropic's official one,
# which Claude Code registers by itself.
if marketplace_known "JuliusBrussee/caveman"; then
  log_skip "marketplace caveman"
else
  run claude plugin marketplace add JuliusBrussee/caveman
fi

for plugin in superpowers@claude-plugins-official caveman@caveman; do
  if plugin_installed "$plugin"; then
    log_skip "plugin $plugin"
  else
    if run claude plugin install --yes --scope user "$plugin"; then
      log_ok "installed $plugin"
    else
      die "could not install $plugin (check network / 'claude plugin marketplace list'), re-run to retry"
    fi
  fi
done

log_info "verify with: claude plugin list   |   authenticate with: claude  (first run)"
