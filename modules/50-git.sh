#!/usr/bin/env bash
# GitHub CLI (gh) as the git credential helper
# shellcheck source=lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"
detect_os

if has gh; then
  log_skip "gh $(gh --version | head -1 | awk '{print $3}')"
else
  case "$PKG" in
    brew)   pkg_install gh ;;
    pacman) pkg_install github-cli ;;
    dnf)    pkg_install gh ;;
    apt)
      # Official GitHub CLI repository (Ubuntu's own package is often stale).
      if [[ "$DRY_RUN" == 1 ]]; then
        run echo "add https://cli.github.com/packages apt repo and install gh"
      else
        sudo mkdir -p -m 755 /etc/apt/keyrings
        curl -fsSL --retry 3 https://cli.github.com/packages/githubcli-archive-keyring.gpg \
          | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
        sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
          | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
        sudo apt-get update -qq
        sudo apt-get install -y --no-install-recommends gh
      fi
      ;;
    *) die "cannot install gh with package manager '$PKG'" ;;
  esac
  log_ok "gh installed"
fi

# The repo's gitconfig points credential.helper at gh; authentication itself is
# interactive (browser/device flow), so only hint at it.
if [[ "$DRY_RUN" != 1 ]] && has gh && ! gh auth status >/dev/null 2>&1; then
  log_warn "gh is not authenticated yet. Run: gh auth login"
fi
