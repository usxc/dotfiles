# dotfiles

[English](README.md) | [日本語](README.ja.md)

macOS 用の個人 dotfiles です。

このリポジトリでは Nix、nix-darwin、Home Manager、flakes を使っています。

Home Manager は nix-darwin に統合しているため、日常的な更新は `./rebuild.sh` で適用します。

## Quick Start

リポジトリを clone します。

```bash
git clone https://github.com/usxc/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

セットアップスクリプトを実行します。

```bash
./setup.sh
```

`setup.sh` は新しい macOS 環境向けのスクリプトです。

Nix を確認し、必要なら `local.nix` を作成し、nix-darwin がすでに入っているかどうかに応じて `bootstrap.sh` または `rebuild.sh` を実行します。

`local.nix` は Git から無視されます。

例:

```nix
{
  username = "your-macos-username";
  hostname = "Your-MacBook-Air";

  git = {
    name = "your-git-name";
    email = "you@example.com";
  };
}
```

Nix が入っていない場合、`setup.sh` は公式 Nix installer を実行する前に確認します。

Nix のインストール後は、ターミナルを再起動してからもう一度 setup を実行します。

```bash
cd ~/dotfiles
./setup.sh
```

## Structure

```text
.
├── flake.nix                 # エントリーポイント (local darwinConfiguration)
├── flake.lock
├── local.nix                 # ローカル環境設定 (Git では無視)
├── setup.sh                  # 新しい macOS 環境のセットアップ
├── bootstrap.sh              # 初回の nix-darwin activation
├── rebuild.sh                # 日常的な rebuild
├── .gitignore
├── hosts/darwin/             # nix-darwin システム設定
├── home/                     # home-manager modules
│   ├── default.nix           # Home Manager エントリーポイント
│   ├── packages.nix          # すべてのパッケージ
│   ├── git.nix               # Git
│   ├── shell.nix             # Zsh
│   ├── prompt.nix            # Starship
│   └── terminals.nix         # ターミナル設定リンク
└── configs/                  # Dotfiles (home-manager でリンク)
    └── ghostty/              # Ghostty
```

## Scripts

### `setup.sh`

新しい macOS 環境のセットアップ用です。

```bash
./setup.sh
```

### `bootstrap.sh`

初回の nix-darwin activation 用です。

Nix と `local.nix` は存在するが、まだ `darwin-rebuild` が入っていない場合に使います。

```bash
./bootstrap.sh
```

通常は `setup.sh` が自動で実行します。

### `rebuild.sh`

設定を編集した後の日常的な rebuild 用です。

```bash
./rebuild.sh
```

## Daily Usage

変更を適用します。

```bash
cd ~/dotfiles
./rebuild.sh
```

flake inputs を更新します。

```bash
cd ~/dotfiles
nix flake update
./rebuild.sh
```

スクリプトの構文を確認します。

```bash
bash -n setup.sh
bash -n bootstrap.sh
bash -n rebuild.sh
```

`local.nix` が Git から無視されているか確認します。

```bash
git check-ignore -v local.nix
```

期待する優先順位:

```text
/run/current-system/sw/bin
/etc/profiles/per-user/<username>/bin
/opt/homebrew/bin
```

## Requirements

```text
macOS
Apple Silicon Mac
Git
Internet connection for first setup
```

`setup.sh` を実行する前に Nix が入っている必要はありません。

Nix がない場合、`setup.sh` がインストール前に確認します。
