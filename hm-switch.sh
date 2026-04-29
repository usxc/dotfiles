#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCAL_NIX_PATH="${DOTFILES_LOCAL_NIX:-$SCRIPT_DIR/local.nix}"

if [ ! -f "$LOCAL_NIX_PATH" ]; then
  echo "local.nix not found: $LOCAL_NIX_PATH"
  exit 1
fi

USERNAME_VALUE="$(
  nix eval --impure --raw --expr "(import \"$LOCAL_NIX_PATH\").username"
)"

cd "$SCRIPT_DIR"

export DOTFILES_LOCAL_NIX="$LOCAL_NIX_PATH"

if command -v home-manager >/dev/null 2>&1; then
  home-manager switch --impure --flake ".#${USERNAME_VALUE}"
else
  nix run home-manager/master -- switch --impure --flake ".#${USERNAME_VALUE}"
fi
