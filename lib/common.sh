#!/usr/bin/env bash
# Shared helpers for dev-bootstrap modules.
# Compatible with bash 3.2 (macOS default) and bash 4/5 (Linux).
#
# Every module does:
#   source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/lib/common.sh"
# and then uses the helpers below. Nothing here has side effects beyond
# defining functions and reading environment variables.

# Guard against double-sourcing.
[[ -n "${DEV_BOOTSTRAP_COMMON_LOADED:-}" ]] && return 0
DEV_BOOTSTRAP_COMMON_LOADED=1

set -o errexit
set -o nounset
set -o pipefail

# ---------------------------------------------------------------------------
# Paths and options (overridable from the environment / install.sh)
# ---------------------------------------------------------------------------
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
DRY_RUN="${DRY_RUN:-0}"
ASSUME_YES="${ASSUME_YES:-0}"
VERBOSE="${VERBOSE:-0}"
BACKUP_ROOT="${BACKUP_ROOT:-$HOME/.dotfiles-backup}"
BACKUP_DIR="${BACKUP_DIR:-$BACKUP_ROOT/$(date +%Y%m%d-%H%M%S)}"
export REPO_ROOT DRY_RUN ASSUME_YES VERBOSE BACKUP_ROOT BACKUP_DIR

# ---------------------------------------------------------------------------
# Configuration: bootstrap.conf (tracked defaults) < bootstrap.local.conf
# (untracked, per machine) < environment variables already set by the caller.
# ---------------------------------------------------------------------------
load_config() {
  local f key val
  for f in "$REPO_ROOT/bootstrap.conf" "$REPO_ROOT/bootstrap.local.conf"; do
    [[ -f "$f" ]] || continue
    while IFS='=' read -r key val; do
      key="${key%%[[:space:]]*}"
      [[ -z "$key" || "$key" == \#* ]] && continue
      val="${val%%#*}"                       # strip trailing comment
      val="${val%"${val##*[![:space:]]}"}"   # trim trailing whitespace
      val="${val#\"}"; val="${val%\"}"       # strip optional quotes
      # A variable already set in the environment (CLI flag, `VAR=x ./install.sh`)
      # wins over the files; bootstrap.local.conf wins over bootstrap.conf.
      if [[ -z "${!key+x}" ]] || [[ "${_cfg_set_by_file:-}" == *":$key:"* ]]; then
        export "$key=$val"
        _cfg_set_by_file="${_cfg_set_by_file:-}:$key:"
      fi
    done < "$f"
  done
  # Defaults for everything the files may leave unset.
  export AI_ASSISTANT="${AI_ASSISTANT:-claude}"
  export CHANGE_SHELL="${CHANGE_SHELL:-1}"
  export NODE_VERSION="${NODE_VERSION:-lts/*}"
  case "$AI_ASSISTANT" in
    claude|copilot|both|none) ;;
    *) die "AI_ASSISTANT must be one of: claude, copilot, both, none (got '$AI_ASSISTANT')" ;;
  esac
}

# wants_ai NAME — true when the configured assistant selection includes NAME.
wants_ai() {
  [[ "$AI_ASSISTANT" == "$1" || "$AI_ASSISTANT" == both ]]
}

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  C_RESET=$'\033[0m'; C_DIM=$'\033[2m'; C_BOLD=$'\033[1m'
  C_RED=$'\033[31m'; C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_BLUE=$'\033[34m'
else
  C_RESET=''; C_DIM=''; C_BOLD=''; C_RED=''; C_GREEN=''; C_YELLOW=''; C_BLUE=''
fi

log_step() { printf '\n%s==> %s%s\n' "$C_BOLD$C_BLUE" "$*" "$C_RESET"; }
log_info() { printf '%s  ·%s %s\n' "$C_DIM" "$C_RESET" "$*"; }
log_ok()   { printf '%s  ✔%s %s\n' "$C_GREEN" "$C_RESET" "$*"; }
log_warn() { printf '%s  !%s %s\n' "$C_YELLOW" "$C_RESET" "$*" >&2; }
log_err()  { printf '%s  ✖ %s%s\n' "$C_RED" "$*" "$C_RESET" >&2; }
log_skip() { printf '%s  –%s %s (already done)\n' "$C_DIM" "$C_RESET" "$*"; }
die()      { log_err "$*"; exit 1; }

# ---------------------------------------------------------------------------
# Command helpers
# ---------------------------------------------------------------------------
has() { command -v "$1" >/dev/null 2>&1; }

# run CMD... — execute, or only print when DRY_RUN=1.
run() {
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '%s  [dry-run]%s %s\n' "$C_YELLOW" "$C_RESET" "$*"
    return 0
  fi
  if [[ "$VERBOSE" == "1" ]]; then
    printf '%s  $ %s%s\n' "$C_DIM" "$*" "$C_RESET"
  fi
  "$@"
}

# sudo_run CMD... — like run, but with sudo when not root (and sudo exists).
sudo_run() {
  if [[ "$(id -u)" -eq 0 ]]; then
    run "$@"
  elif has sudo; then
    run sudo "$@"
  else
    die "need root privileges for: $* (sudo not found)"
  fi
}

# confirm "question" — true when the user says yes, or when ASSUME_YES=1.
confirm() {
  [[ "$ASSUME_YES" == "1" ]] && return 0
  if [[ ! -t 0 ]]; then
    log_warn "non-interactive session and --yes not given; answering no to: $1"
    return 1
  fi
  local reply
  printf '%s? %s [y/N] %s' "$C_BOLD" "$1" "$C_RESET"
  read -r reply
  [[ "$reply" =~ ^[Yy]([Ee][Ss])?$ ]]
}

# ---------------------------------------------------------------------------
# OS detection — sets OS (linux|macos), PKG (apt|dnf|pacman|brew|none), ARCH, IS_WSL
# ---------------------------------------------------------------------------
detect_os() {
  ARCH="$(uname -m)"
  IS_WSL=0
  case "$(uname -s)" in
    Darwin) OS=macos ;;
    Linux)
      OS=linux
      if grep -qi microsoft /proc/version 2>/dev/null; then IS_WSL=1; fi
      ;;
    *) die "unsupported operating system: $(uname -s)" ;;
  esac

  if [[ "$OS" == macos ]]; then
    PKG=brew
  elif has apt-get; then
    PKG=apt
  elif has dnf; then
    PKG=dnf
  elif has pacman; then
    PKG=pacman
  else
    PKG=none
  fi
  export OS PKG ARCH IS_WSL
}

# Homebrew lives in different prefixes on Intel vs Apple Silicon.
brew_prefix() {
  if [[ -x /opt/homebrew/bin/brew ]]; then echo /opt/homebrew
  elif [[ -x /usr/local/bin/brew ]]; then echo /usr/local
  else return 1; fi
}

# pkg_install NAME... — install packages with the detected manager (idempotent).
pkg_install() {
  [[ $# -eq 0 ]] && return 0
  case "$PKG" in
    apt)    sudo_run apt-get install -y --no-install-recommends "$@" ;;
    dnf)    sudo_run dnf install -y "$@" ;;
    pacman) sudo_run pacman -S --noconfirm --needed "$@" ;;
    brew)   run brew install "$@" ;;
    none)   die "no supported package manager found; install manually: $*" ;;
  esac
}

# pkg_installed NAME — true when the package is present.
pkg_installed() {
  case "$PKG" in
    apt)    dpkg -s "$1" >/dev/null 2>&1 ;;
    dnf)    rpm -q "$1" >/dev/null 2>&1 ;;
    pacman) pacman -Qi "$1" >/dev/null 2>&1 ;;
    brew)   brew list --formula "$1" >/dev/null 2>&1 ;;
    *)      return 1 ;;
  esac
}

# ---------------------------------------------------------------------------
# File helpers
# ---------------------------------------------------------------------------
ensure_dir() { [[ -d "$1" ]] || run mkdir -p "$1"; }

# backup_path PATH — move an existing file/dir/symlink into BACKUP_DIR, keeping its
# path relative to $HOME so a backup can be restored by copying it back.
backup_path() {
  local target="$1"
  [[ -e "$target" || -L "$target" ]] || return 0
  local rel="${target#"$HOME"/}"
  local dest="$BACKUP_DIR/$rel"
  ensure_dir "$(dirname "$dest")"
  log_info "backing up $target -> $dest"
  run mv "$target" "$dest"
}

# link_file SRC DST — symlink DST -> SRC, backing up whatever was at DST.
# No-op when DST is already the right symlink.
link_file() {
  local src="$1" dst="$2"
  [[ -e "$src" ]] || die "link_file: source does not exist: $src"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    log_skip "$dst -> $src"
    return 0
  fi
  backup_path "$dst"
  ensure_dir "$(dirname "$dst")"
  run ln -s "$src" "$dst"
  log_ok "$dst -> $src"
}

# copy_if_missing SRC DST — copy a template only when DST does not exist yet.
copy_if_missing() {
  local src="$1" dst="$2"
  if [[ -e "$dst" ]]; then
    log_skip "$dst exists"
    return 0
  fi
  ensure_dir "$(dirname "$dst")"
  run cp "$src" "$dst"
  log_ok "created $dst from template"
}

# git_clone_or_update URL DIR [extra git-clone args]
git_clone_or_update() {
  local url="$1" dir="$2"; shift 2
  if [[ -d "$dir/.git" ]]; then
    log_info "updating $(basename "$dir")"
    run git -C "$dir" pull --quiet --ff-only || log_warn "could not fast-forward $dir (local changes?)"
  else
    run git clone --quiet "$@" "$url" "$dir"
    log_ok "cloned $(basename "$dir")"
  fi
}

# download URL DEST — curl with retries.
download() {
  run curl -fsSL --retry 3 --retry-delay 2 -o "$2" "$1"
}

# append_line_once FILE LINE — append LINE unless FILE already contains it verbatim.
append_line_once() {
  local file="$1" line="$2"
  if [[ -f "$file" ]] && grep -qxF -- "$line" "$file"; then
    return 0
  fi
  if [[ "$DRY_RUN" == "1" ]]; then
    printf '%s  [dry-run]%s append to %s: %s\n' "$C_YELLOW" "$C_RESET" "$file" "$line"
  else
    printf '%s\n' "$line" >> "$file"
  fi
}

# json_merge BASE OVERLAY -> stdout. Deep merge; OVERLAY wins, arrays are unioned
# (order preserved, duplicates dropped). Uses jq when present, python3 otherwise.
json_merge() {
  if has jq; then
    # $-parameters bind values; plain filter parameters would be re-evaluated
    # against the reduce accumulator and return garbage.
    jq -s '
      def merge($a; $b):
        if ($a | type) == "object" and ($b | type) == "object" then
          reduce ($b | keys_unsorted[]) as $k ($a; .[$k] = merge($a[$k]; $b[$k]))
        elif ($a | type) == "array" and ($b | type) == "array" then
          reduce $b[] as $v ($a; if index([$v]) then . else . + [$v] end)
        else $b end;
      merge(.[0]; .[1])
    ' "$1" "$2"
  elif has python3; then
    python3 - "$1" "$2" <<'PY'
import json, sys
def merge(a, b):
    if isinstance(a, dict) and isinstance(b, dict):
        out = dict(a)
        for k, v in b.items():
            out[k] = merge(a[k], v) if k in a else v
        return out
    if isinstance(a, list) and isinstance(b, list):
        out = list(a)
        for v in b:
            if v not in out:
                out.append(v)
        return out
    return b
with open(sys.argv[1]) as fa, open(sys.argv[2]) as fb:
    print(json.dumps(merge(json.load(fa), json.load(fb)), indent=2))
PY
  else
    die "json_merge needs jq or python3"
  fi
}

# json_pretty FILE -> stdout, canonical formatting (for change detection).
json_pretty() {
  if has jq; then jq . "$1"
  else python3 -c 'import json,sys; print(json.dumps(json.load(open(sys.argv[1])), indent=2))' "$1"
  fi
}
