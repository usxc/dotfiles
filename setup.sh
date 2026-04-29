#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCAL_NIX_PATH="$SCRIPT_DIR/local.nix"

die() {
  echo "Error: $*" >&2
  exit 1
}

nix_string_escape() {
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

prompt_required() {
  local label="$1"
  local value=""

  while true; do
    read -r -p "$label: " value
    if [ -n "$value" ]; then
      printf '%s' "$value"
      return
    fi
    echo "入力してください。" >&2
  done
}

prompt_with_default() {
  local label="$1"
  local default_value="${2:-}"
  local value=""

  if [ -n "$default_value" ]; then
    read -r -p "$label [$default_value]: " value
    printf '%s' "${value:-$default_value}"
  else
    prompt_required "$label"
  fi
}

ensure_macos() {
  if [ "$(uname -s)" != "Darwin" ]; then
    die "This setup script is only for macOS."
  fi
}

ensure_nix() {
  if command -v nix >/dev/null 2>&1; then
    echo "Nix already installed: $(command -v nix)"
    return
  fi

  cat <<'EOF'
Nix がまだ入っていません。

これから公式 Nix installer で multi-user install を実行します。
インストール中に sudo パスワードを求められることがあります。

実行するコマンド:
  curl -L https://nixos.org/nix/install | sh -s -- --daemon

EOF

  read -r -p "Nix をインストールしますか？ [y/N]: " answer

  case "$answer" in
    y|Y|yes|YES)
      curl -L https://nixos.org/nix/install | sh -s -- --daemon
      ;;
    *)
      cat <<'EOF'

中止しました。

手動で入れる場合は、以下を実行してください。

  curl -L https://nixos.org/nix/install | sh -s -- --daemon

インストール後、ターミナルを完全に開き直してから、
もう一度 ./setup.sh を実行してください。
EOF
      exit 1
      ;;
  esac

  cat <<'EOF'

Nix のインストール処理が終わりました。

ここで一度ターミナルを完全に閉じて、開き直してください。
その後、もう一度以下を実行してください。

  cd ~/dotfiles
  ./setup.sh

EOF

  exit 0
}

ensure_flakes_config() {
  if nix flake --help >/dev/null 2>&1; then
    echo "Nix flakes already enabled."
    return
  fi

  local nix_conf_dir="$HOME/.config/nix"
  local nix_conf="$nix_conf_dir/nix.conf"

  mkdir -p "$nix_conf_dir"
  touch "$nix_conf"

  if grep -q '^experimental-features' "$nix_conf"; then
    cp "$nix_conf" "$nix_conf.bak"
    sed -i '' '/^experimental-features/d' "$nix_conf"
  fi

  {
    echo
    echo "experimental-features = nix-command flakes"
  } >> "$nix_conf"

  echo "Enabled nix-command and flakes in $nix_conf"
}

ensure_gitignore() {
  local gitignore_path="$SCRIPT_DIR/.gitignore"

  touch "$gitignore_path"

  if ! grep -qx 'local.nix' "$gitignore_path"; then
    echo "local.nix" >> "$gitignore_path"
  fi

  if ! grep -qx '\*.local.nix' "$gitignore_path"; then
    echo "*.local.nix" >> "$gitignore_path"
  fi

  if ! grep -qx '.DS_Store' "$gitignore_path"; then
    echo ".DS_Store" >> "$gitignore_path"
  fi
}

ensure_local_nix() {
  if [ -f "$LOCAL_NIX_PATH" ]; then
    echo "local.nix already exists: $LOCAL_NIX_PATH"
    return
  fi

  local username_value
  local hostname_value
  local current_git_name=""
  local current_git_email=""
  local git_name_value
  local git_email_value

  username_value="$(id -un)"
  hostname_value="$(scutil --get LocalHostName 2>/dev/null || hostname -s)"

  if command -v git >/dev/null 2>&1; then
    current_git_name="$(git config --global user.name 2>/dev/null || true)"
    current_git_email="$(git config --global user.email 2>/dev/null || true)"
  fi

  echo "local.nix が見つからないため作成します。"
  echo
  echo "username: $username_value"
  echo "hostname: $hostname_value"
  echo

  git_name_value="$(prompt_with_default "Git user.name" "$current_git_name")"
  echo
  git_email_value="$(prompt_with_default "Git user.email" "$current_git_email")"
  echo

  cat > "$LOCAL_NIX_PATH" <<EOF
{
  username = "$(nix_string_escape "$username_value")";
  hostname = "$(nix_string_escape "$hostname_value")";

  git = {
    name = "$(nix_string_escape "$git_name_value")";
    email = "$(nix_string_escape "$git_email_value")";
  };
}
EOF

  echo "local.nix を作成しました:"
  echo "  $LOCAL_NIX_PATH"
  echo
  cat "$LOCAL_NIX_PATH"
  echo

  read -r -p "この内容で続行しますか？ [y/N]: " answer

  case "$answer" in
    y|Y|yes|YES)
      ;;
    *)
      echo "local.nix を確認・編集してから、もう一度 ./setup.sh を実行してください。"
      exit 0
      ;;
  esac
}

ensure_bootstrap_script() {
  if [ ! -x "$SCRIPT_DIR/bootstrap.sh" ]; then
    die "bootstrap.sh が見つからないか、実行権限がありません。chmod +x bootstrap.sh を確認してください。"
  fi
}

ensure_rebuild_script() {
  if [ ! -x "$SCRIPT_DIR/rebuild.sh" ]; then
    die "rebuild.sh が見つからないか、実行権限がありません。chmod +x rebuild.sh を確認してください。"
  fi
}

main() {
  ensure_macos
  ensure_nix
  ensure_flakes_config
  ensure_gitignore
  ensure_local_nix
  ensure_bootstrap_script
  ensure_rebuild_script

  echo

  if command -v darwin-rebuild >/dev/null 2>&1; then
    echo "nix-darwin はすでに導入済みです。rebuild.sh を実行します。"
    echo
    "$SCRIPT_DIR/rebuild.sh"
  else
    echo "nix-darwin がまだ導入されていません。bootstrap.sh を実行します。"
    echo
    "$SCRIPT_DIR/bootstrap.sh"
  fi
}

main "$@"
