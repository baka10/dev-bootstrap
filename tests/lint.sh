#!/usr/bin/env bash
# Run ShellCheck on every shell script in the repo (bash dialect; scripts stay bash 3.2 compatible for macOS).
set -o errexit -o nounset -o pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

command -v shellcheck >/dev/null 2>&1 || { echo "shellcheck not installed (apt/brew install shellcheck)"; exit 1; }

files=(install.sh lib/*.sh modules/*.sh tests/*.sh tests/docker/*.sh claude/hooks/*.sh)
shellcheck --shell=bash --external-sources --severity=style "${files[@]}"
echo "shellcheck: ${#files[@]} files OK"

# Scripts must be executable in git, or `./install.sh` fails after clone.
bad=0
for f in install.sh modules/*.sh tests/*.sh tests/docker/run.sh claude/hooks/*.sh; do
  [[ -x "$f" ]] || { echo "not executable: $f"; bad=1; }
done
exit "$bad"
