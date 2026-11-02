#!/usr/bin/env bash
# Symlink dotfiles (zshrc, p10k, git) into $HOME, backing up anything in the way
# shellcheck source=lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"
detect_os

D="$REPO_ROOT/dotfiles"

# Tracked files: edit them in the repo, commit, and every machine follows.
link_file "$D/zshrc"            "$HOME/.zshrc"
link_file "$D/p10k.zsh"         "$HOME/.p10k.zsh"
link_file "$D/gitconfig"        "$HOME/.gitconfig"
link_file "$D/gitignore_global" "$HOME/.config/git/ignore"

# Local files: created once from a template, never tracked, never overwritten.
# This is where machine-specific paths, secrets and your git identity live.
copy_if_missing "$D/zshrc.local.example"     "$HOME/.zshrc.local"
copy_if_missing "$D/gitconfig.local.example" "$HOME/.gitconfig.local"

if [[ "$DRY_RUN" != 1 ]]; then
  if ! grep -Eq '^[[:space:]]*name[[:space:]]*=' "$HOME/.gitconfig.local" 2>/dev/null; then
    log_warn "set your git identity in ~/.gitconfig.local ([user] name / email)"
  fi
fi
