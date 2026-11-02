# Troubleshooting

**Prompt shows boxes or question marks instead of icons**
The terminal font is not MesloLGS NF. Set it in the terminal (not the shell).
On WSL the font must be installed on Windows and selected in Windows Terminal.
Then `p10k configure` if you want a different style.

**`zsh: command not found: nvm` / `node`**
nvm loads lazily through the oh-my-zsh `nvm` plugin; the first `node`, `npm`
or `nvm` call loads it. If `~/.nvm` is missing, run `./install.sh --only runtimes`.

**`chsh: PAM: Authentication failure` or shell did not change**
Run `chsh -s "$(command -v zsh)"` yourself (it asks for your password). In
containers and some CI images `chsh` is unavailable; set `CHANGE_SHELL=0`.

**`sudo: a password is required` in a non-interactive run**
The `packages` and `git` modules need sudo on Linux. Run them in a terminal,
or pre-install the packages and use `--skip packages,git`.

**`jq`/`python3` not found when merging settings**
`json_merge` uses jq or python3. Run `./install.sh --only packages` first, or
install either tool.

**Claude Code: `claude: command not found` right after install**
The native installer puts the binary in `~/.local/bin`, which the new
`.zshrc` adds to `PATH`. Open a new shell and run `./install.sh --only claude-code`
again to finish the plugin step.

**Claude Code plugin install fails or asks for confirmation**
Plugins come from marketplaces; `claude plugin marketplace list` should show
`claude-plugins-official` and `caveman`. Re-add with
`claude plugin marketplace add JuliusBrussee/caveman`, then
`claude plugin install --yes caveman@caveman`.

**Hook did not run**
Check `~/.claude/settings.json` has the `hooks` block and that the scripts are
executable (`ls -l ~/.claude/hooks`). Hooks run with `~` expanded by the shell;
`/hooks` inside Claude Code lists what is active.

**Copilot CLI: `copilot` not found**
On Linux it is installed with npm from nvm's Node; open a new shell so `PATH`
includes it, or run `npm i -g @github/copilot` manually. On macOS: `brew install copilot-cli`.

**macOS: `bash: declare -A: invalid option`**
Something used a bash 4 feature. The repo targets bash 3.2 on purpose; please
open an issue with the module name.

**I want my old config back**
See *Backups and rollback* in [usage.md](usage.md): everything replaced is in
`~/.dotfiles-backup/<timestamp>/`.
