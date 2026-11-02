# dev-bootstrap

One command turns a fresh **Linux** or **macOS** machine into a ready development
environment: a configured zsh with Powerlevel10k, tracked dotfiles, language
runtimes, GitHub CLI, and an AI coding assistant (Claude Code and/or GitHub
Copilot) wired up with instructions, guard-rail hooks and skills.

```bash
git clone https://github.com/baka10/dev-bootstrap.git ~/projects/dev-bootstrap
cd ~/projects/dev-bootstrap
./install.sh
```

Run it again any time: every step is idempotent and reports what is already in place.

## What you get

| Module | Installs / configures |
|---|---|
| `packages` | zsh, git, curl, fzf, ripgrep, fd, bat, jq, shellcheck (apt / dnf / pacman / brew) |
| `zsh` | oh-my-zsh, Powerlevel10k, zsh-autosuggestions, zsh-syntax-highlighting, zsh as login shell |
| `fonts` | MesloLGS Nerd Font (brew cask on macOS, `~/.local/share/fonts` on Linux) |
| `dotfiles` | `~/.zshrc`, `~/.p10k.zsh`, `~/.gitconfig`, global gitignore — **symlinked** from `dotfiles/`, originals backed up |
| `runtimes` | nvm + Node (LTS by default), uv for Python |
| `git` | GitHub CLI; git uses `gh` as credential helper |
| `claude-code` | Claude Code CLI, plugins **superpowers** + **caveman**, global `CLAUDE.md`, merged `settings.json`, hooks, custom skill |
| `copilot` | GitHub Copilot CLI, `~/.copilot/config.json`, instruction templates |

Which assistant is set up is a single setting, `AI_ASSISTANT`, in
[`bootstrap.conf`](bootstrap.conf): `claude` (default), `copilot`, `both` or `none`.
Override it per machine in `bootstrap.local.conf` or per run with `./install.sh --ai copilot`.

## Usage

```bash
./install.sh --dry-run          # show what would change, touch nothing
./install.sh --yes              # non-interactive (CI, fresh VM)
./install.sh --only zsh,dotfiles
./install.sh --skip fonts
./install.sh --ai both          # Claude Code and Copilot
./install.sh --list             # modules and what they do
make test                       # shellcheck + smoke tests, no changes to your machine
make test-docker                # full install in a clean ubuntu:24.04 container
```

After the first run: open a new terminal, set the terminal font to **MesloLGS NF**,
and put your git identity in `~/.gitconfig.local`. Everything machine-specific
(secrets, `JAVA_HOME`, extra `PATH` entries) goes to `~/.zshrc.local`, which the
repo creates once from a template and never touches again.

## Layout

```
install.sh            entry point: option parsing, OS detection, runs modules in order
bootstrap.conf        tracked defaults (AI_ASSISTANT, CHANGE_SHELL, NODE_VERSION)
lib/common.sh         logging, dry-run, package manager abstraction, backup + symlink, JSON merge
modules/NN-name.sh    one idempotent step each; runnable on their own
dotfiles/             zshrc, p10k.zsh, gitconfig, gitignore_global + *.example templates
claude/               CLAUDE.md, settings.json, hooks/, skills/, templates/
copilot/              config.json, templates/
docs/                 usage, customising, AI workflow, troubleshooting, design spec
tests/                lint.sh (shellcheck), smoke.sh, docker/ (clean-room install)
.github/workflows     CI: lint + smoke + real install on ubuntu and macos + docker
```

## Documentation

- [Usage](docs/usage.md) — options, what each module does, backups and rollback
- [Customising](docs/customizing.md) — adding a module, changing the prompt, per-machine config
- [AI-assisted development](docs/ai-workflow.md) — how Claude Code, Superpowers, Caveman, hooks, skills and Copilot fit together, and the day-to-day workflow
- [Troubleshooting](docs/troubleshooting.md)
- [Design spec](docs/superpowers/specs/2026-11-02-dev-bootstrap-design.md)

## Requirements

- Linux with apt, dnf or pacman (Ubuntu 22.04+/Debian 12+, Fedora, Arch; WSL2 works) or macOS 13+
- `curl`, `git`, and `sudo` for package installation; everything else is installed by the script
- bash 3.2+ (the macOS default) — the scripts avoid bash 4 features on purpose

## License

MIT — see [LICENSE](LICENSE).
