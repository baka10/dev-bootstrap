---
name: conventional-commit
description: Use when writing a git commit message, when the user asks to commit, or when summarising a change for a PR title. Produces Conventional Commits (type(scope): summary) from the staged diff.
---

# Conventional commit

Write commit messages that a changelog generator and a reviewer can both use.

## Steps

1. Look at what is staged: `git diff --cached --stat` and `git diff --cached`.
   If nothing is staged, say so and stop; do not stage files on your own.
2. Pick ONE type from the table. If the diff needs two types, it is two commits: say so.
3. Scope is the module, package or area touched (`zsh`, `api`, `auth`, `docs`). Omit it when the change is global.
4. Summary: imperative mood, lower-case, no trailing period, 72 characters max.
   "add nvm lazy loading", not "Added nvm lazy loading." or "This adds…".
5. Body (optional, wrapped at 72): what changed and why, not how. Reference issues as `Refs #123` or `Closes #123`.
6. Breaking change: add `!` after the type/scope and a `BREAKING CHANGE:` footer.

## Types

| type | use for |
|---|---|
| feat | new user-visible behaviour |
| fix | bug fix |
| docs | documentation only |
| refactor | code change that is neither feat nor fix |
| test | tests only |
| build | build system, dependencies, installers |
| ci | CI configuration |
| chore | maintenance that touches no src or test |
| perf | performance improvement |

## Output

Show the final message in a fenced block, then run exactly:

```
git commit -m "<message>"
```

only if the user asked you to commit. Otherwise stop after showing the message.
