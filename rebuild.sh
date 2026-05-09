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
    DARWIN_REBUILD_BIN="$(command -v darwin-rebuild || true)"

    if [[ -z "$DARWIN_REBUILD_BIN" ]]; then
      echo "Error: darwin-rebuild not found." >&2
      echo "Run: ./bootstrap.sh" >&2
      echo "If you just ran bootstrap.sh successfully, open a new shell and try again." >&2
      exit 1
    fi

    info "Rebuilding Apple Silicon macOS configuration: $TARGET"

    DOTFILES_LOCAL_NIX="$LOCAL_NIX_PATH" \
      sudo --preserve-env=DOTFILES_LOCAL_NIX \
      "$DARWIN_REBUILD_BIN" switch --impure --flake ".#${TARGET}"
    ;;

  linux)
    HOME_MANAGER_BIN="$(command -v home-manager || true)"

    if [[ -z "$HOME_MANAGER_BIN" ]]; then
      echo "Error: home-manager not found." >&2
      echo "Run: ./bootstrap.sh" >&2
      echo "If you just ran bootstrap.sh successfully, open a new shell and try again." >&2
      exit 1
    fi

    info "Rebuilding Home Manager configuration: $TARGET"

    DOTFILES_LOCAL_NIX="$LOCAL_NIX_PATH" \
      "$HOME_MANAGER_BIN" switch --impure --flake ".#${TARGET}"
    ;;

  *)
    die "Unknown platform: $PLATFORM"
    ;;
esac
