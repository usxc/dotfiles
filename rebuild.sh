#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCAL_NIX_PATH="${DOTFILES_LOCAL_NIX:-$SCRIPT_DIR/local.nix}"

if [ ! -f "$LOCAL_NIX_PATH" ]; then
  echo "local.nix not found: $LOCAL_NIX_PATH"
  exit 1
fi

HOSTNAME_VALUE="$(
  nix eval --impure --raw --expr "(import \"$LOCAL_NIX_PATH\").hostname"
)"

cd "$SCRIPT_DIR"

DOTFILES_LOCAL_NIX="$LOCAL_NIX_PATH" \
  sudo --preserve-env=DOTFILES_LOCAL_NIX \
  darwin-rebuild switch --impure --flake ".#${HOSTNAME_VALUE}"
