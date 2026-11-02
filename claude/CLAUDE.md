# Global instructions (~/.claude/CLAUDE.md)

These apply to every project. A project's own CLAUDE.md adds to them and wins on conflict.

## How I work with you

- Think before coding. For anything beyond a one-line fix, say what you plan to change and why, then do it. Use the Superpowers workflow: brainstorm the design, write a plan, implement with tests, verify, then ask for review.
- Small, reviewable steps. Prefer several focused changes over one large one.
- Verify before claiming. Run the tests, linter or build and show the result. "Should work" is not done.
- When unsure, ask one precise question instead of guessing. When the request is clear, do not ask for permission to start.
- Read the existing code and follow its conventions (naming, structure, error handling, test style) before introducing new ones.

## Code

- Tests first when adding behaviour; a failing test defines the task.
- No dead code, no commented-out blocks, no speculative abstractions. Three similar lines beat a premature helper.
- Handle errors where they can be handled; otherwise let them propagate with context.
- Keep secrets out of code, logs and commits. Never read or print `.env` files, keys or tokens unless asked explicitly.
- Do not add dependencies without saying so.

## Git

- Conventional Commits: `type(scope): summary` (use the `conventional-commit` skill).
- Never commit or push unless asked. Never force-push, rewrite shared history or run destructive git commands without explicit confirmation.
- One logical change per commit.

## Communication

- Lead with the outcome, then the essentials. Short sentences. No filler.
- Code goes in fenced blocks, prose stays prose.
- Report failures honestly, including what was not verified.
