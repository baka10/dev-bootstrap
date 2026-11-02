#!/usr/bin/env bash
# MesloLGS Nerd Font (the font Powerlevel10k is designed for)
# shellcheck source=lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"
detect_os

if [[ "$OS" == macos ]]; then
  if brew list --cask font-meslo-lg-nerd-font >/dev/null 2>&1; then
    log_skip "font-meslo-lg-nerd-font"
  else
    run brew install --cask font-meslo-lg-nerd-font
    log_ok "installed MesloLGS Nerd Font"
  fi
  log_info "select 'MesloLGS NF' in Terminal.app / iTerm2 / Ghostty preferences"
  exit 0
fi

# Linux: user-level font directory, no sudo needed.
FONT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/fonts"
BASE_URL="https://github.com/romkatv/powerlevel10k-media/raw/master"
ensure_dir "$FONT_DIR"
installed=0
for style in Regular Bold Italic "Bold Italic"; do
  file="MesloLGS NF $style.ttf"
  if [[ -f "$FONT_DIR/$file" ]]; then
    log_skip "$file"
    continue
  fi
  # Spaces in the URL must be percent-encoded.
  download "$BASE_URL/${file// /%20}" "$FONT_DIR/$file"
  log_ok "downloaded $file"
  installed=1
done
if [[ "$installed" == 1 ]] && has fc-cache; then
  run fc-cache -f "$FONT_DIR"
fi

if [[ "$IS_WSL" == 1 ]]; then
  log_warn "WSL: the terminal runs on Windows, so install the font there too:"
  log_warn "  download the four 'MesloLGS NF' .ttf files from"
  log_warn "  https://github.com/romkatv/powerlevel10k#fonts and double-click each to install,"
  log_warn "  then set 'MesloLGS NF' as the font in Windows Terminal settings."
fi
