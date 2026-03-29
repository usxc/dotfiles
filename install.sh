#!/usr/bin/env bash
set -euo pipefail

# このスクリプトが置かれている dotfiles リポジトリの絶対パス
DOTFILES_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

# 既存ファイルを退避するバックアップ先
BACKUP_DIR="$HOME/dotbackup/$(date +%Y%m%d-%H%M%S)"

# 1 のときは実行せず、実行予定のコマンドだけ表示する
DRY_RUN=0

# 管理対象のファイル一覧
TARGETS=(
  ".zshrc"
  ".config/ghostty/config.ghostty"
  ".config/wezterm"
  ".config/starship.toml"
)

usage() {
  cat <<'EOF'
使い方: ./install.sh [--dry-run]
EOF
}

run() {
  printf '+'
  printf ' %q' "$@"
  printf '\n'

  # dry-run でなければ実際にコマンドを実行する
  if [ "$DRY_RUN" -eq 0 ]; then
    "$@"
  fi
}

link_one() {
  local rel="$1"
  local src="$DOTFILES_DIR/$rel"
  local dst="$HOME/$rel"

  # dotfiles 側に元ファイルが存在しない場合は中断する
  if [ ! -e "$src" ]; then
    echo "ソースが見つかりません: $src" >&2
    exit 1
  fi

  # リンク先ディレクトリがなければ作成する
  run mkdir -p "$(dirname "$dst")"

  # すでに正しいシンボリックリンクなら何もしない
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "スキップ: $dst"
    return
  fi

  # 既存ファイルまたは既存リンクがある場合はバックアップへ退避する
  if [ -e "$dst" ] || [ -L "$dst" ]; then
    local backup="$BACKUP_DIR/$rel"
    run mkdir -p "$(dirname "$backup")"
    run mv "$dst" "$backup"
    echo "バックアップ: $dst -> $backup"
  fi

  # dotfiles のファイルをホーム配下へシンボリックリンクする
  run ln -s "$src" "$dst"
  echo "リンク作成: $dst -> $src"
}

# オプション解析
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "不明なオプションです: $1" >&2
      usage
      exit 1
      ;;
  esac
  shift
done

# 管理対象を順番にリンクする
for rel in "${TARGETS[@]}"; do
  link_one "$rel"
done

echo "インストール完了"
