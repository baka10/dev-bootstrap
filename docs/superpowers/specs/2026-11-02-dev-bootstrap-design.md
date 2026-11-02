# dev-bootstrap — design spec

Date: 2026-11-02

## Goal

A single repository that turns a fresh Linux or macOS machine into a ready
development environment in one command, and that documents how AI-assisted
development is set up on top of it (Claude Code or GitHub Copilot, Superpowers,
Caveman, global instructions, hooks, skills).

Success looks like: `git clone … && ./install.sh` on Ubuntu 24.04 and on macOS
produces the same shell (oh-my-zsh + Powerlevel10k with the owner's prompt
config), the same dotfiles (symlinked from the repo), Node via nvm, uv, gh, and
a configured AI assistant. Running it a second time changes nothing and reports
that everything is already in place.

## Non-goals

- Windows-native setup (WSL is covered as Linux; the Windows Terminal font step
  is documented, not automated).
- Managing secrets. Local values live in `~/.zshrc.local` and
  `~/.gitconfig.local`, which the repo creates once and never touches again.
- Package-manager abstraction beyond apt, dnf, pacman and brew.

## Decisions

| Topic | Decision |
|---|---|
| Entry point | `install.sh` with `--dry-run`, `--yes`, `--only`, `--skip`, `--ai`, `--list` |
| Configuration | `bootstrap.conf` (tracked) < `bootstrap.local.conf` (ignored) < environment / CLI flag |
| AI assistant | `AI_ASSISTANT=claude\|copilot\|both\|none` gates the `claude-code` and `copilot` modules |
| Modules | Numbered standalone bash scripts in `modules/`; each sources `lib/common.sh`, loads config, is idempotent |
| Dotfiles | Symlinks from `dotfiles/` into `$HOME`; previous files moved to `~/.dotfiles-backup/<timestamp>` |
| Shell compat | bash 3.2 (macOS default) for every script; zsh only inside dotfiles |
| Claude Code | native installer, plugins `superpowers@claude-plugins-official` + `caveman@caveman`, global `CLAUDE.md`, `settings.json` deep-merged (jq or python3), PreToolUse + PostToolUse hooks, one custom skill |
| Copilot | `@github/copilot` via npm (brew on macOS), `~/.copilot/config.json`, instruction template |
| Testing | shellcheck on every script; host-safe smoke tests (dry-run, config precedence, library, hooks); Docker `ubuntu:24.04` clean-room install; GitHub Actions on ubuntu + macos |
| Docs language | English |

## Module list

| Module | Does |
|---|---|
| `00-packages` | zsh git curl wget unzip fzf ripgrep fd bat jq shellcheck fontconfig(linux) |
| `10-zsh` | oh-my-zsh, powerlevel10k, zsh-autosuggestions, zsh-syntax-highlighting, `chsh` (unless `CHANGE_SHELL=0`) |
| `20-fonts` | MesloLGS Nerd Font (brew cask on macOS, `~/.local/share/fonts` on Linux) |
| `30-dotfiles` | symlink zshrc, p10k.zsh, gitconfig, gitignore_global; create `~/.zshrc.local` and `~/.gitconfig.local` from templates once |
| `40-runtimes` | nvm + Node (`NODE_VERSION`), uv |
| `50-git` | gh CLI; gitconfig uses gh as credential helper |
| `60-claude-code` | Claude Code CLI, plugins, `~/.claude` files, hooks, skills |
| `61-copilot` | GitHub Copilot CLI, `~/.copilot/config.json` |

## Error handling

`set -euo pipefail` everywhere. A module failure aborts the run with the module
name; previous modules stay applied and are idempotent, so re-running is safe.
Network steps use curl `--retry 3`. Optional tools (formatters in the hook,
jq when python3 exists) are skipped silently. The installer never deletes a
user file: everything replaced is moved to the backup directory.
