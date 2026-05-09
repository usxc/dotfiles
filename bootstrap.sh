#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_NIX_PATH="${DOTFILES_LOCAL_NIX:-$HOME/.config/dotfiles/local.nix}"

NIX_FLAGS=(
  --extra-experimental-features nix-command
  --extra-experimental-features flakes
)

NIX_BIN=""

die() {
  echo "Error: $*" >&2
  exit 1
}

info() {
  echo "==> $*"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    *)
      die "Unknown option: $1"
      ;;
  esac
done

ensure_nix() {
  NIX_BIN="$(command -v nix || true)"
  [[ -n "$NIX_BIN" ]] || die "nix command not found. Install Nix first, then open a new shell."
}

require_local_nix() {
  if [[ ! -f "$LOCAL_NIX_PATH" ]]; then
    echo "Error: local.nix not found: $LOCAL_NIX_PATH" >&2
    echo "Run: ./init-local.sh" >&2
    exit 1
  fi
}

nix_eval_raw() {
  local expr="$1"

  DOTFILES_LOCAL_NIX="$LOCAL_NIX_PATH" \
    "$NIX_BIN" "${NIX_FLAGS[@]}" eval --impure --raw --expr "$expr"
}

local_value() {
  local attr="$1"

  nix_eval_raw "
    let
      localPath = builtins.getEnv \"DOTFILES_LOCAL_NIX\";
      local =
        if localPath == \"\"
        then throw \"DOTFILES_LOCAL_NIX is not set.\"
        else import localPath;
    in
      if local ? ${attr}
      then local.${attr}
      else throw \"local.nix is missing required field: ${attr}\"
  "
}

target_name() {
  local platform

  platform="$(local_value platform)"

  case "$platform" in
    darwin)
      local_value hostname
      ;;
    linux)
      echo "$(local_value username)@$(local_value hostname)"
      ;;
    *)
      die "Unknown platform: $platform"
      ;;
  esac
}

ensure_nix
require_local_nix

cd "$ROOT_DIR"

PLATFORM="$(local_value platform)"
TARGET="$(target_name)"

case "$PLATFORM" in
  darwin)
    info "Bootstrapping Apple Silicon macOS configuration: $TARGET"

    DOTFILES_LOCAL_NIX="$LOCAL_NIX_PATH" \
      sudo --preserve-env=DOTFILES_LOCAL_NIX \
      "$NIX_BIN" "${NIX_FLAGS[@]}" run --impure --inputs-from . nix-darwin#darwin-rebuild -- \
        switch --impure --flake ".#${TARGET}"
    ;;

  linux)
    info "Bootstrapping Home Manager configuration: $TARGET"

    DOTFILES_LOCAL_NIX="$LOCAL_NIX_PATH" \
      "$NIX_BIN" "${NIX_FLAGS[@]}" run --impure --inputs-from . home-manager#home-manager -- \
        switch -b backup --impure --flake ".#${TARGET}"
    ;;

  *)
    die "Unknown platform: $PLATFORM"
    ;;
esac
