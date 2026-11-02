# Usage

## First run

```bash
git clone https://github.com/baka10/dev-bootstrap.git ~/projects/dev-bootstrap
cd ~/projects/dev-bootstrap
./install.sh --dry-run    # optional: read what will happen
./install.sh
```

The installer asks before changing your login shell and before installing
Homebrew on macOS; everything else is non-destructive (files in the way are
backed up, never deleted). On Linux it calls `sudo` only inside the `packages`
and `git` modules.

Then:

1. Open a new terminal (or `exec zsh`).
2. Set the terminal font to **MesloLGS NF** (Terminal.app, iTerm2, Ghostty,
   Windows Terminal for WSL).
3. Edit `~/.gitconfig.local` with your name and e-mail.
4. `gh auth login`, then `claude` (first run signs you in) and/or `copilot` → `/login`.

## Options

| Option | Effect |
|---|---|
| `--dry-run` | Print every command instead of running it. Safe to run anywhere. |
| `-y`, `--yes` | Answer yes to prompts. Required when stdin is not a terminal. |
| `--only a,b` | Run only these modules (names from `--list`). |
| `--skip a,b` | Run everything except these modules. |
| `--ai claude\|copilot\|both\|none` | Which AI assistant to set up this run. |
| `--list` | Module names and one-line descriptions. |
| `-v`, `--verbose` | Echo each command before running it. |

Environment variables `DRY_RUN=1`, `ASSUME_YES=1`, `VERBOSE=1` and every key
from `bootstrap.conf` (`AI_ASSISTANT`, `CHANGE_SHELL`, `NODE_VERSION`) are
honoured as well, which is handy in CI.

## Configuration precedence

1. CLI flag (`--ai`) or exported variable (`AI_ASSISTANT=both ./install.sh`)
2. `bootstrap.local.conf` (git-ignored, per machine)
3. `bootstrap.conf` (tracked defaults)

## Modules

Modules live in `modules/` and run in numeric order. Each one can also be run
on its own: `bash modules/30-dotfiles.sh`.

| Module | Linux | macOS |
|---|---|---|
| `00-packages` | apt / dnf / pacman | brew (Homebrew is installed on demand) |
| `10-zsh` | clones oh-my-zsh + theme + plugins into `~/.oh-my-zsh`; `chsh` | same |
| `20-fonts` | downloads MesloLGS NF to `~/.local/share/fonts`; `fc-cache` | `brew install --cask font-meslo-lg-nerd-font` |
| `30-dotfiles` | symlinks; creates `~/.zshrc.local` and `~/.gitconfig.local` once | same |
| `40-runtimes` | nvm (without touching `.zshrc`) + Node, uv | same |
| `50-git` | official GitHub CLI apt repo / dnf / pacman | `brew install gh` |
| `60-claude-code` | native installer → `~/.local/bin/claude`; plugins; `~/.claude/*` | same |
| `61-copilot` | `npm i -g @github/copilot` (or official installer) | `brew install copilot-cli` |

## Backups and rollback

Anything the `dotfiles` or `claude-code` module replaces is moved to
`~/.dotfiles-backup/<YYYYMMDD-HHMMSS>/` keeping its path relative to `$HOME`.
To roll back a file:

```bash
rm ~/.zshrc
cp ~/.dotfiles-backup/20261102-193000/.zshrc ~/.zshrc
```

Nothing else is deleted. Removing the repo's effects entirely means deleting
the symlinks and, if you want, `~/.oh-my-zsh`, `~/.nvm`, `~/.local/bin/{claude,uv}`.

## Updating

```bash
cd ~/projects/dev-bootstrap && git pull && ./install.sh
```

Dotfiles are symlinks, so a `git pull` alone already updates them; re-running
the installer picks up new modules, plugins and settings keys.
