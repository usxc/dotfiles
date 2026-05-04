# dotfiles

[English](README.md) | [日本語](README.ja.md)

macOS 用の個人 dotfiles です。

このリポジトリでは Nix、nix-darwin、Home Manager、flakes を使っています。

Home Manager は nix-darwin に統合しているため、日常的な更新は `./rebuild.sh` で適用します。

## Initial Setup

### macOS

#### 1. Nix をインストールする

Nix がまだ入っていない場合は、先に Nix をインストールします。

Nix modern installer を使う場合:

```bash
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install
```

インストール後、ターミナルを開き直します。

Nix が使えることを確認します。

```bash
nix --version
```

#### 2. リポジトリを clone する

```bash
git clone https://github.com/usxc/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

#### 3. `local.nix` を作成する

`local.nix.example` から `local.nix` を作成します。

```bash
cp local.nix.example local.nix
$EDITOR local.nix
```

`local.nix` には、この Mac 固有の設定を書きます。

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

各値は以下のコマンドで確認できます。

| key | command |
|---|---|
| `username` | `id -un` |
| `hostname` | `scutil --get LocalHostName` または `hostname -s` |
| `git.name` | `git config --global user.name` |
| `git.email` | `git config --global user.email` |

Git のユーザー名やメールアドレスが未設定の場合は、先に設定します。

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

その後、同じ値を `local.nix` に書きます。

`local.nix` はこの Mac 固有の設定です。Git にはコミットしません。

#### 4. nix-darwin を初回適用する

初回の nix-darwin activation を実行します。

```bash
./bootstrap.sh
```

これで nix-darwin と Home Manager の設定が初回適用されます。

以降の日常的な更新には `./rebuild.sh` を使います。

## Daily Usage

設定変更を反映します。

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

## Scripts

### `bootstrap.sh`

初回の nix-darwin activation 用です。

Nix は入っているが、まだ `darwin-rebuild` が使えない状態で実行します。

```bash
./bootstrap.sh
```

### `rebuild.sh`

設定を編集した後の日常的な rebuild 用です。

```bash
./rebuild.sh
```

## Structure

```text
.
├── flake.nix                 # エントリーポイント
├── flake.lock
├── local.nix.example         # ローカル設定の例
├── local.nix                 # ローカル環境設定 (Git では無視)
├── bootstrap.sh              # 初回の nix-darwin activation
├── rebuild.sh                # 日常的な rebuild
├── .gitignore
├── hosts/darwin/             # nix-darwin システム設定
├── home/                     # Home Manager modules
│   ├── default.nix           # Home Manager エントリーポイント
│   ├── packages.nix          # パッケージ
│   ├── git.nix               # Git
│   ├── shell.nix             # Zsh
│   ├── prompt.nix            # Starship
│   └── terminals.nix         # ターミナル設定リンク
└── configs/                  # Home Manager でリンクする dotfiles
    └── ghostty/              # Ghostty
    └── aerospace/            # AeroSpace
```

## Requirements

```text
macOS
Apple Silicon Mac
Nix
Git
```
