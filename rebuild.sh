#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCAL_NIX_PATH="${DOTFILES_LOCAL_NIX:-$SCRIPT_DIR/local.nix}"

die() {
  echo "Error: $*" >&2
  exit 1
}

ensure_macos() {
  if [ "$(uname -s)" != "Darwin" ]; then
    die "This script is only for macOS."
  fi
}

ensure_nix() {
  if ! command -v nix >/dev/null 2>&1; then
    die "Nix is not installed. Run ./setup.sh first."
  fi
}

ensure_local_nix() {
  if [ ! -f "$LOCAL_NIX_PATH" ]; then
    die "local.nix not found: $LOCAL_NIX_PATH. Run ./setup.sh first."
  fi
}

ensure_darwin_rebuild() {
  if ! command -v darwin-rebuild >/dev/null 2>&1; then
    die "darwin-rebuild is not installed yet. Run ./bootstrap.sh first."
  fi
}

main() {
  ensure_macos
  ensure_nix
  ensure_local_nix
  ensure_darwin_rebuild

  local hostname_value

  hostname_value="$(
    nix eval --impure --raw --expr "(import \"$LOCAL_NIX_PATH\").hostname"
  )"

  cd "$SCRIPT_DIR"

  DOTFILES_LOCAL_NIX="$LOCAL_NIX_PATH" \
    sudo --preserve-env=DOTFILES_LOCAL_NIX \
    darwin-rebuild switch --impure --flake ".#${hostname_value}"
}

main "$@"
