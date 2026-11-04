# dotfiles

[English](README.md) · [日本語セットアップ](docs/setup.ja.md)

Nix（nix-darwin / Home Manager / flakes）で管理するdotfilesです。
Apple Silicon macOSとx86_64 Linux / WSLに対応しています。

## Quick Start

Nixが利用可能で、Gitのglobal設定に `user.name` と `user.email` が設定済みであることが前提です。
準備が必要な場合は、[初期セットアップ](docs/setup.ja.md#初期セットアップ)から進めてください。

```bash
git clone https://github.com/usxc/dotfiles.git ~/dotfiles
cd ~/dotfiles
make init
```

`make init` は `~/.config/dotfiles/local.nix` を生成し、初回適用します（既存ファイルは保持）。
Nix自体のインストールは含みません。macOSでは管理者認証が必要です。
既存Git設定の扱いは[Git設定の移行](docs/setup.ja.md#git設定の移行)を参照してください。

makeがない場合は `./scripts/init-local.sh && ./scripts/bootstrap.sh` を直接実行できます。
適用後はターミナルを開き直してください。Linux/WSLでは必要に応じて[zshへ切り替えます](docs/setup.ja.md#zsh)。

## Daily Usage

リポジトリ内で実行します。`make` / `make help` で操作一覧を表示できます。

```bash
# 設定変更を反映
make rebuild
```

依存関係の更新は、次のどちらか一方を選びます（`flake.lock` の更新のみ）。

| コマンド | 更新対象 |
| --- | --- |
| `make update-nixpkgs` | Nixpkgsのみ |
| `make update-all` | 全inputs |

```bash
# 更新の差分を確認し、問題がなければ反映
git diff -- flake.lock
make rebuild
```

[更新範囲と固定バージョン](docs/setup.ja.md#inputsの更新)、makeを使わない[直接実行](docs/setup.ja.md#スクリプトの直接実行)は補足を参照してください。
`local.nix` の保存先を変えた場合は、初回・再適用で同じ `DOTFILES_LOCAL_NIX` を指定します（[指定例](docs/setup.ja.md#localnix)）。

## Structure

```text
.
├── Makefile                  # 操作の入口（makeで一覧表示）
├── flake.nix                 # flakeエントリーポイント
├── flake.lock                # 固定されたflake inputs
├── local.nix.example         # マシン固有設定の例
├── scripts/                  # 初期化・適用スクリプト
│   ├── init-local.sh         # local.nix生成
│   ├── bootstrap.sh          # 初回適用
│   └── rebuild.sh            # 日常の再適用
├── home/                     # Home Managerモジュール
│   ├── common/               # 全環境共通の設定
│   │   ├── packages.nix      # 共通の開発ツール・ランタイム
│   │   ├── git.nix           # Gitユーザー情報・LFS・既存設定の移行
│   │   ├── shell.nix         # Zsh・補完・エディタ選択
│   │   ├── prompt.nix        # Starship
│   │   └── direnv.nix        # direnv・nix-direnv
│   ├── darwin/               # macOS専用の設定
│   │   ├── packages.nix      # macOS専用パッケージ
│   │   └── terminals.nix     # Ghostty設定リンク
│   └── linux/                # Linux / WSL用の設定
│       ├── packages.nix      # Linux専用パッケージ
│       ├── session.nix       # セッション環境変数
│       └── wsl.nix           # WSL専用設定・ブラウザー連携
├── hosts/darwin/             # nix-darwinのシステム設定
│   └── default.nix           # Nix・ユーザー・sudo認証
├── pkgs/                     # 独自パッケージ定義
│   └── nodejs-bin.nix        # Node.js（公式バイナリ）
├── configs/ghostty/
│   └── config.ghostty        # Ghosttyの外観・キーバインド
└── docs/setup.md             # セットアップ・操作の補足
```

## Requirements

- macOS：Apple Silicon
- Linux / WSL：x86_64（[WSL2 / systemdの準備](docs/setup.ja.md#wsl)）
- Git・Nix（makeは任意）
