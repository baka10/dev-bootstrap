#!/usr/bin/env bash
# Build the test image: a successful build means the installer ran from zero,
# ran a second time without changes, and zsh starts with the configured theme.
set -o errexit -o nounset -o pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../.."
command -v docker >/dev/null 2>&1 || { echo "docker is required"; exit 1; }
docker build --progress=plain -f tests/docker/Dockerfile -t dev-bootstrap-test .
echo "docker test passed; try it: docker run --rm -it dev-bootstrap-test zsh"
