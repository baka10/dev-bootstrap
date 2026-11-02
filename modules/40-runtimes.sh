#!/usr/bin/env bash
# Language runtimes: nvm + Node LTS, uv (Python)
# shellcheck source=lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"
load_config
detect_os

# --- nvm + Node ---------------------------------------------------------------
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
export NVM_DIR
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  log_skip "nvm in $NVM_DIR"
else
  log_info "installing nvm"
  # PROFILE=/dev/null stops the installer from editing ~/.zshrc; the repo's
  # zshrc already loads nvm (lazily).
  if [[ "$DRY_RUN" == 1 ]]; then
    run echo "curl nvm install.sh | PROFILE=/dev/null bash"
  else
    curl -fsSL --retry 3 https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | PROFILE=/dev/null bash
  fi
  log_ok "nvm installed"
fi

if [[ "$DRY_RUN" != 1 && -s "$NVM_DIR/nvm.sh" ]]; then
  # shellcheck source=/dev/null
  set +o nounset; . "$NVM_DIR/nvm.sh"; set -o nounset
  if nvm ls --no-colors "$NODE_VERSION" >/dev/null 2>&1; then
    log_skip "Node $NODE_VERSION ($(nvm version "$NODE_VERSION"))"
  else
    log_info "installing Node $NODE_VERSION"
    nvm install "$NODE_VERSION" >/dev/null
    nvm alias default "$NODE_VERSION" >/dev/null
    log_ok "Node $(node --version)"
  fi
else
  run echo "nvm install $NODE_VERSION"
fi

# --- uv (Python package & project manager) -----------------------------------
if has uv || [[ -x "$HOME/.local/bin/uv" ]]; then
  log_skip "uv"
else
  log_info "installing uv"
  if [[ "$DRY_RUN" == 1 ]]; then
    run echo "curl astral.sh/uv/install.sh | sh"
  else
    curl -fsSL --retry 3 https://astral.sh/uv/install.sh | UV_NO_MODIFY_PATH=1 sh
  fi
  log_ok "uv installed to ~/.local/bin"
fi
