#!/usr/bin/env bash
set -euo pipefail

LOCAL_NIX_PATH="${DOTFILES_LOCAL_NIX:-$HOME/.config/dotfiles/local.nix}"
FORCE=false

die() {
  echo "Error: $*" >&2
  exit 1
}

info() {
  echo "==> $*"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      FORCE=true
      shift
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
done

escape_nix_string() {
  local value="$1"

  if [[ "$value" == *$'\n'* || "$value" == *$'\r'* ]]; then
    die "Nix string values must not contain newlines."
  fi

  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//\$\{/\\\$\{}"

  printf '%s' "$value"
}

detect_platform() {
  local os
  os="$(uname -s)"

  case "$os" in
    Darwin)
      echo "darwin"
      ;;
    Linux)
      echo "linux"
      ;;
    *)
      die "Unsupported OS: $os"
      ;;
  esac
}

detect_system() {
  local platform="$1"
  local arch

  arch="$(uname -m)"

  case "$platform:$arch" in
    darwin:arm64|darwin:aarch64)
      echo "aarch64-darwin"
      ;;
    linux:x86_64)
      echo "x86_64-linux"
      ;;
    darwin:x86_64)
      die "This dotfiles supports macOS only on Apple Silicon. Intel Mac is not supported."
      ;;
    linux:aarch64|linux:arm64)
      die "This dotfiles supports Linux/WSL only on x86_64. ARM Linux is not supported."
      ;;
    *)
      die "Unsupported system: platform=$platform arch=$arch"
      ;;
  esac
}

detect_hostname() {
  local platform="$1"
  local value=""

  if [[ "$platform" == "darwin" ]] && command -v scutil >/dev/null 2>&1; then
    value="$(scutil --get LocalHostName 2>/dev/null || true)"
  fi

  if [[ -z "$value" && "$platform" == "linux" && -n "${WSL_DISTRO_NAME:-}" ]]; then
    value="$(printf '%s' "$WSL_DISTRO_NAME" | tr '[:upper:]' '[:lower:]')"
  fi

  if [[ -z "$value" ]]; then
    value="$(hostname -s 2>/dev/null || hostname 2>/dev/null || true)"
  fi

  [[ -n "$value" ]] || die "Could not detect hostname."

  printf '%s\n' "$value"
}

detect_is_wsl() {
  if [[ "$(uname -s)" != "Linux" ]]; then
    echo "false"
    return
  fi

  if grep -qiE "microsoft|wsl" /proc/sys/kernel/osrelease 2>/dev/null; then
    echo "true"
    return
  fi

  if grep -qiE "microsoft|wsl" /proc/version 2>/dev/null; then
    echo "true"
    return
  fi

  if [[ -n "${WSL_DISTRO_NAME:-}" || -n "${WSL_INTEROP:-}" ]]; then
    echo "true"
    return
  fi

  echo "false"
}

get_git_config() {
  local key="$1"

  git config --global --get "$key" 2>/dev/null || true
}

if [[ -f "$LOCAL_NIX_PATH" && "$FORCE" != true ]]; then
  echo "local.nix already exists: $LOCAL_NIX_PATH"
  echo "Use './init-local.sh --force' to overwrite it."
  exit 0
fi

command -v git >/dev/null 2>&1 || die "git command not found. Install Git first."

PLATFORM="$(detect_platform)"
SYSTEM="$(detect_system "$PLATFORM")"
USERNAME="$(id -un)"
HOSTNAME_VALUE="$(detect_hostname "$PLATFORM")"
HOME_DIRECTORY="$HOME"
IS_WSL="$(detect_is_wsl)"

[[ -n "$USERNAME" ]] || die "Could not detect username."
[[ -n "$HOME_DIRECTORY" ]] || die "Could not detect home directory."

GIT_NAME="$(get_git_config user.name)"
GIT_EMAIL="$(get_git_config user.email)"

if [[ -z "$GIT_NAME" || -z "$GIT_EMAIL" ]]; then
  echo "Error: Git user.name or user.email is not configured globally." >&2
  echo >&2
  echo "Set them with:" >&2
  echo "  git config --global user.name \"Your Name\"" >&2
  echo "  git config --global user.email \"you@example.com\"" >&2
  echo >&2
  echo "Then run:" >&2
  echo "  ./init-local.sh" >&2
  exit 1
fi

mkdir -p "$(dirname "$LOCAL_NIX_PATH")"

TMP_FILE="$(mktemp "${LOCAL_NIX_PATH}.tmp.XXXXXX")"

{
  echo "{"
  echo "  username = \"$(escape_nix_string "$USERNAME")\";"
  echo "  hostname = \"$(escape_nix_string "$HOSTNAME_VALUE")\";"
  echo
  echo "  platform = \"$PLATFORM\";"
  echo "  system = \"$SYSTEM\";"
  echo "  homeDirectory = \"$(escape_nix_string "$HOME_DIRECTORY")\";"
  echo

  if [[ "$IS_WSL" == "true" ]]; then
    echo "  isWsl = true;"
    echo
  fi

  echo "  git = {"
  echo "    name = \"$(escape_nix_string "$GIT_NAME")\";"
  echo "    email = \"$(escape_nix_string "$GIT_EMAIL")\";"
  echo "  };"
  echo "}"
} > "$TMP_FILE"

mv "$TMP_FILE" "$LOCAL_NIX_PATH"

info "Created: $LOCAL_NIX_PATH"
echo
echo "Detected:"
echo "  platform      = $PLATFORM"
echo "  system        = $SYSTEM"
echo "  username      = $USERNAME"
echo "  hostname      = $HOSTNAME_VALUE"
echo "  homeDirectory = $HOME_DIRECTORY"
echo "  isWsl         = $IS_WSL"
echo "  git.name      = $GIT_NAME"
echo "  git.email     = $GIT_EMAIL"
