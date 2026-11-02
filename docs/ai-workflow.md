# AI-assisted development setup

This repo does not just install an AI CLI. It sets up the *process* around it:
instructions the assistant always sees, guard-rails that run outside the model,
reusable skills, and a workflow that keeps the human in charge of design and review.

## Pieces

| Layer | Claude Code | GitHub Copilot CLI |
|---|---|---|
| Always-on instructions | `~/.claude/CLAUDE.md` (global) + `CLAUDE.md` per project | `.github/copilot-instructions.md` or `AGENTS.md` per project |
| Process skills | **superpowers** plugin: brainstorming → spec → plan → TDD → review | — (use the same checklist from the instructions file) |
| Output style | **caveman** plugin: terse answers, fewer tokens | `~/.copilot/config.json` |
| Guard-rails | hooks: `protect-paths` (PreToolUse), `format-on-edit` (PostToolUse); `permissions.deny` | repo-level branch protection and CI |
| Reusable know-how | skills: `conventional-commit` (+ any `SKILL.md` you add) | — |
| Permissions | `permissions.allow` for read-only commands, `deny` for secrets and force-push | approve per command in the CLI |

Everything above is a file in this repo, symlinked or merged into `~/.claude`
and `~/.copilot` by `modules/60-claude-code.sh` and `modules/61-copilot.sh`.
Switch between assistants with `AI_ASSISTANT` in `bootstrap.conf` or
`./install.sh --ai …`.

## Why each piece exists

- **Global CLAUDE.md** states the non-negotiables once: verify before claiming,
  small steps, no secrets, conventional commits, honest reporting. Project
  files add the project's commands and layout (template in
  `claude/templates/project-CLAUDE.md`).
- **Superpowers** turns "build me X" into a conversation about the design, a
  written spec, a plan, and test-first implementation. The design spec for
  this very repo was produced that way: `docs/superpowers/specs/`.
- **Caveman** cuts the prose in replies; useful when you run many sessions a day.
  Disable it per session with `/caveman off` or remove it from `enabledPlugins`.
- **Hooks** enforce what instructions can only ask for. `protect-paths.sh`
  refuses edits to `.env`, keys and lock files (exit code 2 blocks the tool call
  and tells Claude why). `format-on-edit.sh` runs prettier / ruff / gofmt /
  rustfmt / shfmt / terraform fmt after every edit when they are installed, so
  formatting never shows up in review.
- **Permissions** pre-approve harmless read-only commands so the session does
  not stop every few seconds, and deny the handful of commands that should
  always involve a human.
- **Skills** package a repeatable procedure with its trigger description.
  `conventional-commit` is the example; copy its structure for your own.

## Day-to-day workflow

1. **Start in the project** with a `CLAUDE.md` (or `AGENTS.md`) that lists the
   commands to build, test and lint. Without it the assistant guesses.
2. **Brainstorm first** for anything non-trivial: `/superpowers:brainstorm` (or
   describe the goal; the skill triggers on its own). Answer its questions, agree on a design.
3. **Plan, then execute**: for multi-file work let it write a plan
   (`docs/superpowers/plans/`), review it, then execute task by task.
4. **TDD**: ask for the failing test before the implementation. The
   `test-driven-development` skill enforces the order.
5. **Verify**: the assistant must run `make test` / `make lint` and paste the
   output. "Should work" is not done (this is in the global CLAUDE.md).
6. **Review**: `/code-review` or the `requesting-code-review` skill before
   merging. Treat findings as input, not orders — verify them.
7. **Commit** with the `conventional-commit` skill. The assistant never pushes
   or force-pushes on its own (denied in settings).

## Keeping it honest

- Hooks and `permissions.deny` run outside the model: they hold even when the
  prompt is wrong.
- Secrets live in `~/.zshrc.local`, `.env` and the OS keychain, which the
  assistant is denied from reading and editing.
- Every file that shapes assistant behaviour is version-controlled here, so a
  change to how the assistant works is a reviewable commit.

## Useful commands

```bash
claude                          # start; /help, /plugin, /hooks, /memory
claude plugin list              # installed plugins
claude plugin marketplace list
claude --resume                 # continue the last session (alias: ccr)
copilot                         # Copilot CLI; /login, /help
```
