#!/usr/bin/env bash
# oh-my-zsh + Powerlevel10k + autosuggestions + syntax-highlighting, zsh as login shell
# shellcheck source=lib/common.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"
load_config
detect_os

# In a dry run the packages module has not actually run, so only warn.
for tool in zsh git; do
  if ! has "$tool"; then
    if [[ "$DRY_RUN" == 1 ]]; then
      log_warn "$tool is not installed yet (the 'packages' module installs it)"
    else
      die "$tool is not installed (run the 'packages' module first)"
    fi
  fi
done

ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$ZSH_DIR/custom}"

# oh-my-zsh is cloned directly instead of using its install script: the script
# would rewrite ~/.zshrc and call chsh on its own, which the dotfiles module
# and this module handle in a controlled way.
if [[ -d "$ZSH_DIR/.git" ]]; then
  log_skip "oh-my-zsh in $ZSH_DIR"
else
  git_clone_or_update https://github.com/ohmyzsh/ohmyzsh.git "$ZSH_DIR" --depth=1
fi

git_clone_or_update https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k" --depth=1
git_clone_or_update https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_CUSTOM/plugins/zsh-autosuggestions" --depth=1
git_clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" --depth=1

# Make zsh the login shell.
zsh_path="$(command -v zsh || echo /usr/bin/zsh)"
if [[ "${SHELL:-}" == "$zsh_path" ]]; then
  log_skip "login shell is $zsh_path"
elif [[ "$CHANGE_SHELL" != 1 ]]; then
  log_info "CHANGE_SHELL=0: leaving the login shell as is"
else
  if [[ "$OS" == linux && -f /etc/shells ]] && ! grep -qxF "$zsh_path" /etc/shells; then
    log_info "registering $zsh_path in /etc/shells"
    if [[ "$DRY_RUN" == "1" ]]; then
      run echo "$zsh_path >> /etc/shells"
    else
      echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null
    fi
  fi
  if confirm "Change login shell to $zsh_path?"; then
    if run chsh -s "$zsh_path"; then
      log_ok "login shell set to $zsh_path (takes effect at next login)"
    else
      log_warn "chsh failed; run manually: chsh -s $zsh_path"
    fi
  fi
fi
