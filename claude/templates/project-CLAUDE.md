# <Project name>

<!-- Copy this file to the root of a project as CLAUDE.md and fill in the blanks.
     Keep it short: Claude reads it on every turn. Link to docs instead of pasting them. -->

## What this is

One paragraph: what the project does, who uses it, what "done" means for a change.

## Commands

```bash
make setup      # install dependencies
make test       # run the test suite (must pass before any commit)
make lint       # linters / type checks
make run        # start locally
```

## Layout

- `src/` — application code, organised by domain, not by layer
- `tests/` — mirrors `src/`; one test file per module
- `docs/` — ADRs in `docs/adr/`, design specs in `docs/superpowers/specs/`

## Conventions

- Language/runtime version: …
- Formatting and linting are enforced by hooks; do not hand-format.
- Error handling: …
- Naming: …

## Workflow

1. Brainstorm the change (`/superpowers:brainstorm`) and agree on a design.
2. Write a plan for anything larger than one file.
3. TDD: failing test, minimal implementation, refactor.
4. Run `make test` and `make lint`; paste the result in the final message.
5. Commit with a Conventional Commit message; one logical change per commit.

## Do not

- Do not edit generated files in `…`.
- Do not change the public API in `…` without an ADR.
- Do not touch secrets or deployment configuration.
