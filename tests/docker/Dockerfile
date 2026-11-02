# Clean Ubuntu used to prove the installer works from zero.
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update -qq \
 && apt-get install -y --no-install-recommends sudo ca-certificates curl git \
 && rm -rf /var/lib/apt/lists/* \
 && useradd -m -s /bin/bash dev \
 && echo 'dev ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/dev

USER dev
WORKDIR /home/dev/dev-bootstrap
COPY --chown=dev:dev . .

# Everything except Claude Code plugins, which need an authenticated account.
RUN ./install.sh --yes --skip claude-code \
 && zsh -ic 'echo "zsh ok: $ZSH_THEME"' \
 && ./install.sh --yes --skip claude-code | tee /tmp/second-run.log \
 && grep -q 'already done' /tmp/second-run.log
