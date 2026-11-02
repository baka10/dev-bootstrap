#!/usr/bin/env bash
# dev-bootstrap — one command to set up a Linux or macOS development machine.
#
# Usage:
#   ./install.sh [options]
#
# Options:
#   --dry-run          Print what would be done, change nothing.
#   -y, --yes          Assume "yes" for every prompt (non-interactive).
#   --only a,b,c       Run only the named modules (names without the number prefix).
#   --skip a,b,c       Run everything except the named modules.
#   --ai claude|copilot|both|none
#                      Which AI coding assistant to set up (default from bootstrap.conf).
#   --list             List available modules and exit.
#   -v, --verbose      Echo each command before running it.
#   -h, --help         Show this help.
#
# Modules run in numeric order from ./modules. Every module is idempotent:
# running the installer twice is safe and reports what is already in place.

set -o errexit
set -o nounset
set -o pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REPO_ROOT
# shellcheck source=lib/common.sh
source "$REPO_ROOT/lib/common.sh"

usage() { sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'; }

list_modules() {
  local m name desc
  for m in "$REPO_ROOT"/modules/[0-9][0-9]-*.sh; do
    name="$(basename "$m" .sh)"; name="${name#[0-9][0-9]-}"
    desc="$(sed -n '2s/^# \{0,1\}//p' "$m")"
    printf '  %-14s %s\n' "$name" "$desc"
  done
}

# in_list NAME "a,b,c"
in_list() {
  local needle="$1" list="$2" item
  [[ -z "$list" ]] && return 1
  local old_ifs="$IFS"
  IFS=','
  for item in $list; do
    if [[ "$item" == "$needle" ]]; then IFS="$old_ifs"; return 0; fi
  done
  IFS="$old_ifs"
  return 1
}

ONLY=""
SKIP=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)      DRY_RUN=1 ;;
    -y|--yes)       ASSUME_YES=1 ;;
    -v|--verbose)   VERBOSE=1 ;;
    --only)         ONLY="${2:-}"; shift ;;
    --only=*)       ONLY="${1#--only=}" ;;
    --skip)         SKIP="${2:-}"; shift ;;
    --skip=*)       SKIP="${1#--skip=}" ;;
    --ai)           export AI_ASSISTANT="${2:-}"; shift ;;
    --ai=*)         export AI_ASSISTANT="${1#--ai=}" ;;
    --list)         list_modules; exit 0 ;;
    -h|--help)      usage; exit 0 ;;
    *)              die "unknown option: $1 (see --help)" ;;
  esac
  shift
done
export DRY_RUN ASSUME_YES VERBOSE

# Fail on typos in --only/--skip instead of silently running nothing.
known_modules=""
for m in "$REPO_ROOT"/modules/[0-9][0-9]-*.sh; do
  n="$(basename "$m" .sh)"; known_modules="$known_modules,${n#[0-9][0-9]-}"
done
for sel in "$ONLY" "$SKIP"; do
  [[ -z "$sel" ]] && continue
  old_ifs="$IFS"; IFS=','
  for n in $sel; do
    in_list "$n" "${known_modules#,}" || { IFS="$old_ifs"; die "unknown module '$n' (see --list)"; }
  done
  IFS="$old_ifs"
done

load_config
detect_os
log_step "dev-bootstrap"
log_info "os=$OS pkg=$PKG arch=$ARCH wsl=$IS_WSL dry-run=$DRY_RUN ai=$AI_ASSISTANT"
log_info "repo: $REPO_ROOT"
[[ "$DRY_RUN" == "1" ]] || log_info "backups: $BACKUP_DIR"

if [[ "$PKG" == "brew" ]] && ! has brew; then
  log_step "Homebrew"
  if confirm "Homebrew is required on macOS. Install it now?"; then
    run /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    prefix="$(brew_prefix)" && eval "$("$prefix/bin/brew" shellenv)"
  else
    die "Homebrew is required: https://brew.sh"
  fi
fi

failed=""
ran=0
for module in "$REPO_ROOT"/modules/[0-9][0-9]-*.sh; do
  name="$(basename "$module" .sh)"; name="${name#[0-9][0-9]-}"
  if [[ -n "$ONLY" ]] && ! in_list "$name" "$ONLY"; then continue; fi
  if in_list "$name" "$SKIP"; then log_info "skipping $name"; continue; fi
  log_step "module: $name"
  if bash "$module"; then
    ran=$((ran + 1))
  else
    failed="$name"
    break
  fi
done

if [[ -n "$failed" ]]; then
  log_err "module '$failed' failed. Fix the problem and re-run; completed modules are idempotent."
  exit 1
fi

log_step "done ($ran module(s))"
if [[ "$DRY_RUN" == "1" ]]; then
  log_info "dry run: nothing was changed"
else
  log_info "open a new terminal (or run: exec zsh) to load the new shell"
  log_info "set your terminal font to 'MesloLGS NF'; run 'p10k configure' if glyphs look wrong"
fi
