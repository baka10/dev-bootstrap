#!/usr/bin/env bash
# Base CLI packages: zsh git curl fzf ripgrep fd bat jq shellcheck
# shellcheck source=lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"
detect_os

# Package names differ per distro; keep the mapping in one place.
case "$PKG" in
  apt)    WANT="zsh git curl wget unzip ca-certificates fzf ripgrep fd-find bat jq shellcheck fontconfig" ;;
  dnf)    WANT="zsh git curl wget unzip ca-certificates fzf ripgrep fd-find bat jq ShellCheck fontconfig" ;;
  pacman) WANT="zsh git curl wget unzip ca-certificates fzf ripgrep fd bat jq shellcheck fontconfig" ;;
  brew)   WANT="git curl wget fzf ripgrep fd bat jq shellcheck" ;;   # zsh ships with macOS
  *)      die "no supported package manager (apt, dnf, pacman, brew) found" ;;
esac

missing=""
for p in $WANT; do
  if pkg_installed "$p"; then
    log_skip "$p"
  else
    missing="$missing $p"
  fi
done

if [[ -z "$missing" ]]; then
  log_ok "all base packages present"
else
  log_info "installing:$missing"
  [[ "$PKG" == apt ]] && sudo_run apt-get update -qq
  # shellcheck disable=SC2086  # intentional word splitting of the package list
  pkg_install $missing
fi

# Debian/Ubuntu install `fd` and `bat` under different binary names. Expose the
# canonical names in ~/.local/bin so scripts and the dotfiles can rely on them.
if [[ "$PKG" == apt ]]; then
  ensure_dir "$HOME/.local/bin"
  if has fdfind && ! has fd; then run ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"; log_ok "fd -> fdfind"; fi
  if has batcat && ! has bat; then run ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"; log_ok "bat -> batcat"; fi
fi
