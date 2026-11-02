<!-- Copy to <project>/.github/copilot-instructions.md (read by Copilot CLI, Copilot
     in VS Code and Copilot coding agent). For a tool-agnostic file use AGENTS.md
     at the project root instead; Copilot CLI reads that too. Keep it short. -->

# <Project name>

## What this is

One paragraph: what the project does, who uses it, what "done" means for a change.

## Commands

- Setup: `make setup`
- Tests: `make test` (must pass before any commit)
- Lint: `make lint`

## Conventions

- Follow the existing code style; formatting is enforced by tooling, do not hand-format.
- Tests first for new behaviour. Small, focused changes.
- Conventional Commits: `type(scope): summary`.
- Never commit secrets, never edit lock files by hand, never force-push.

## Workflow

1. Explain the plan before changing more than one file.
2. Implement with tests.
3. Run `make test` and `make lint`; include the result in your summary.
