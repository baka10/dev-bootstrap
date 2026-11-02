# Customising

## Per-machine settings

| File | Tracked | Purpose |
|---|---|---|
| `bootstrap.conf` | yes | defaults for everyone using the repo |
| `bootstrap.local.conf` | no | overrides on this machine (e.g. `AI_ASSISTANT=both`) |
| `~/.zshrc.local` | no | shell: secrets, `JAVA_HOME`, machine-only aliases |
| `~/.gitconfig.local` | no | git identity, signing key |

The installer creates the `~/*.local` files once from `dotfiles/*.example` and
never writes to them again.

## The prompt

`dotfiles/p10k.zsh` is a Powerlevel10k wizard output (classic powerline style,
two lines, transient prompt). To change it, run `p10k configure`: it rewrites
`~/.p10k.zsh`, which is a symlink into the repo, so the result lands in the
repo and can be committed. Hand-edits work the same way.

## Adding a module

1. Create `modules/NN-name.sh`. Line 2 is the description shown by `--list`.
2. Start with the standard header:

   ```bash
   #!/usr/bin/env bash
   # One-line description
   # shellcheck source=lib/common.sh
   source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"
   load_config
   detect_os
   ```

3. Use the helpers so `--dry-run` keeps working: `run`, `sudo_run`,
   `pkg_install`, `link_file`, `copy_if_missing`, `git_clone_or_update`,
   `download`, `confirm`, `log_*`.
4. Make it idempotent: check before acting, print `log_skip` when nothing is to do.
5. `chmod +x`, then `make test`. The smoke test runs every module in dry-run mode.

Helpers are documented inline in [`lib/common.sh`](../lib/common.sh).

## Adding a dotfile

Put the file in `dotfiles/`, add one `link_file` line to `modules/30-dotfiles.sh`,
run `./install.sh --only dotfiles`.

## Claude Code

- Global behaviour: `claude/CLAUDE.md` (symlinked to `~/.claude/CLAUDE.md`).
- Settings: `claude/settings.json` is **deep-merged** into `~/.claude/settings.json`;
  keys you add locally survive re-runs. Arrays (permission lists) are unioned.
- Hooks: scripts in `claude/hooks/` are symlinked into `~/.claude/hooks/` and
  referenced from `settings.json`. Add a new one the same way.
- Skills: each directory under `claude/skills/` with a `SKILL.md` is linked into
  `~/.claude/skills/`; add a line to `modules/60-claude-code.sh` for a new one.
- Plugins: the list lives in `modules/60-claude-code.sh` (`for plugin in …`) and
  in `settings.json` (`enabledPlugins`). Keep both in sync.
- New project: copy `claude/templates/project-CLAUDE.md` to `<project>/CLAUDE.md`.

## GitHub Copilot

- `copilot/config.json` is symlinked to `~/.copilot/config.json`.
- Project instructions: copy `copilot/templates/copilot-instructions.md` to
  `<project>/.github/copilot-instructions.md`, or keep a tool-agnostic
  `AGENTS.md` at the project root (Copilot CLI reads both).

## Removing things you do not want

Delete the module file, or add it to `--skip` in your own alias, e.g.
`alias bootstrap='~/projects/dev-bootstrap/install.sh --skip fonts'`.
