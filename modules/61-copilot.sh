#!/usr/bin/env bash
# GitHub Copilot CLI (terminal coding agent) + instruction templates
# shellcheck source=lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"
load_config
detect_os

if ! wants_ai copilot; then
  log_info "AI_ASSISTANT=$AI_ASSISTANT: skipping GitHub Copilot (set it to copilot or both in bootstrap.conf)"
  exit 0
fi

export PATH="$HOME/.local/bin:$PATH"
# Pick up Node from nvm when this shell has not loaded it yet (npm install path).
if ! has npm && [[ -s "${NVM_DIR:-$HOME/.nvm}/nvm.sh" ]]; then
  # shellcheck source=/dev/null
  set +o nounset; . "${NVM_DIR:-$HOME/.nvm}/nvm.sh"; set -o nounset
fi

# --- CLI ----------------------------------------------------------------------
if has copilot; then
  log_skip "copilot $(copilot --version 2>/dev/null | head -1)"
else
  if [[ "$OS" == macos ]]; then
    log_info "installing GitHub Copilot CLI (brew)"
    run brew install copilot-cli
  elif has npm; then
    log_info "installing GitHub Copilot CLI (npm -g @github/copilot)"
    run npm install -g @github/copilot
  else
    log_info "installing GitHub Copilot CLI (official installer -> ~/.local/bin)"
    if [[ "$DRY_RUN" == 1 ]]; then
      run echo "curl -fsSL https://gh.io/copilot-install | bash"
    else
      curl -fsSL --retry 3 https://gh.io/copilot-install | bash
    fi
  fi
  if has copilot; then log_ok "copilot installed"; else log_warn "copilot not on PATH yet; open a new shell"; fi
fi

# --- Global config (~/.copilot) ----------------------------------------------
# The CLI rewrites config.json itself (trusted folders, model, state), so it is
# seeded once from the repo and never linked. Project instructions come from
# AGENTS.md / .github/copilot-instructions.md (template in copilot/templates).
COPILOT_HOME="$HOME/.copilot"
ensure_dir "$COPILOT_HOME"
copy_if_missing "$REPO_ROOT/copilot/config.json" "$COPILOT_HOME/config.json"

if [[ "$DRY_RUN" != 1 ]] && has copilot; then
  log_info "authenticate with: copilot  then  /login   (or set GH_TOKEN / use gh auth login)"
fi
