# セットアップと操作の補足

[English](setup.md)

普段の操作はREADMEの [Quick Start](../README.ja.md#quick-start) / [Daily Usage](../README.ja.md#daily-usage) を参照してください。

## 初期セットアップ

Apple Silicon macOS・x86_64 Linux / WSLで共通の手順です。Gitとcurlを事前に用意してください。
makeは任意で、未導入でもスクリプトを直接実行できます。

### 1. Nixを準備する

WSLの場合は、先に[WSLの準備](#wsl)を確認してください。
Nixが未導入の場合は、flakesを有効にしてインストールします。

```bash
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes
```

インストール後はターミナルを開き直し、Nixが使えることを確認します。
すでに利用可能な場合は再インストール不要です。

```bash
nix --version
```

### 2. リポジトリを取得する

```bash
git clone https://github.com/usxc/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 3. Gitのユーザー情報を確認する

マシン固有の設定を作るため、Gitのglobal設定から名前とメールアドレスを読み取ります。
`include` や `~/.config/git/config` にあるglobal設定も読み取り、`init-local.sh` が必要な情報を確認します。
未設定の場合は、自分の情報を登録してください。

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

認証・署名・includeなどを設定済みの場合は、[Git設定の移行](#git設定の移行)も確認してください。

### 4. 設定を生成して適用する

```bash
make init
```

`./scripts/init-local.sh` が成功した後に `./scripts/bootstrap.sh` を実行します。前者が失敗した場合は初回適用へ進みません。
makeがない場合の同じ操作は次のとおりです。

```bash
./scripts/init-local.sh && ./scripts/bootstrap.sh
```

マシン固有の設定は、Git管理に含めないリポジトリ外の `~/.config/dotfiles/local.nix` に生成します。
保存先変更や既存ファイルの扱いは [local.nix](#localnix) を参照してください。
macOSではnix-darwinとHome Manager、Linux/WSLではHome Managerの設定が適用されます。
macOSではスクリプト内で管理者認証を求めます。`sudo make` は不要です。
これらのスクリプトはNix自体をインストールしません。

適用後はターミナルを開き直してください。
Linux/WSLでzshをログインシェルにする場合は、[zshの切り替え](#zsh)へ進んでください。

## WSL

ここで案内しているNixのインストール方法では、WSL2でsystemdを有効にした環境を使います。
Nixがすでに使える場合は、再インストールせず[Nixの確認手順](#1-nixを準備する)へ進んでください。

PowerShellで、使用するディストリビューションの `VERSION` が `2` であることを確認します。

```powershell
wsl --list --verbose
```

systemdの利用にはWSL 0.67.6以降が必要です。
`wsl --version` で確認し、古い場合やコマンドが使えない場合は `wsl --update` で更新してください。

WSL内で、systemdが起動しているか確認します。

```bash
ps -p 1 -o comm=
```

`systemd` と表示されれば、この設定は済んでいます。
表示されない場合は、WSL内の `/etc/wsl.conf` で次の設定を有効にしてください。
既存の設定を残し、`[boot]` セクションの `systemd` を `true` に設定します。
セクションや項目がなければ追加してください。

```ini
[boot]
systemd=true
```

PowerShellで次を実行し、WSLを開き直します。このコマンドは起動中のWSL環境をすべて停止します。

```powershell
wsl --shutdown
```

再度 `ps -p 1 -o comm=` で確認したら、[Nixのインストール手順](#1-nixを準備する)へ戻ります。
systemdの導入が必要な場合など、環境ごとの詳細は [Microsoftの公式手順](https://learn.microsoft.com/en-us/windows/wsl/systemd) を参照してください。
NixのWSL対応については [Nix Installerの公式手順](https://github.com/NixOS/nix-installer#in-wsl2) に説明があります。

## zsh

Linux/WSLではzshの設定を適用しても、ログインシェルは自動では変更されません。
初回適用後にターミナルを開き直し、zshをログインシェルにする場合は次を実行します。

```bash
ZSH_PATH="$(command -v zsh)"

if [ -z "$ZSH_PATH" ]; then
  echo "zsh not found"
  exit 1
fi

if ! grep -qxF "$ZSH_PATH" /etc/shells; then
  printf '%s\n' "$ZSH_PATH" | sudo tee -a /etc/shells
fi

chsh -s "$ZSH_PATH"
```

Linuxではログインし直してください。WSLではPowerShellで `wsl --shutdown` を実行してから開き直します。

```bash
echo "$SHELL"
```

表示されたパスがzshを指していれば完了です。

## local.nix

`./scripts/init-local.sh` は、マシン固有の設定を既定では `~/.config/dotfiles/local.nix` に生成します。
生成される項目とOSごとの値は [local.nix.example](../local.nix.example) を参照してください。

既存のファイルは通常の実行では上書きされません。
新規生成では、同じファイルシステム上の一時ファイルをハードリンクで公開し、同時実行による上書きも防ぎます。
ハードリンク非対応の保存先では通常の新規生成は停止します。`--force` は従来どおりファイルの置換を行います。
保存先がディレクトリやリンク切れの場合は、既存のパスを変更せずエラーで停止します。
既存ファイルがある場合、`init-local.sh` は成功して終了するため、`make init` はその設定で初回適用を続けます。
内容を確認して作り直す場合だけ、明示的に `--force` を指定します。`make init` はこのオプションを付けません。

```bash
./scripts/init-local.sh --force
```

保存先を変更する場合は、リポジトリ外のパスを指定します。
相対パスを指定した場合は、コマンドを実行するディレクトリを基準に解決します。
`make init` は両スクリプトへ同じ `DOTFILES_LOCAL_NIX` を引き継ぎます。

```bash
DOTFILES_LOCAL_NIX=/path/to/local.nix make init
DOTFILES_LOCAL_NIX=/path/to/local.nix make rebuild
```

直接実行する場合も、生成・初回適用・再適用で同じパスを渡してください。

```bash
DOTFILES_LOCAL_NIX=/path/to/local.nix ./scripts/init-local.sh &&
DOTFILES_LOCAL_NIX=/path/to/local.nix ./scripts/bootstrap.sh
```

以降の再適用でも、同じパスを指定します。

```bash
DOTFILES_LOCAL_NIX=/path/to/local.nix ./scripts/rebuild.sh
```

保存先を変えて再生成する場合も、`DOTFILES_LOCAL_NIX=/path/to/local.nix ./scripts/init-local.sh --force` と指定します。

## Git設定の移行

`init-local.sh` が取り込むGit設定はglobalの `user.name` と `user.email` です。
[home/common/git.nix](../home/common/git.nix) はこの情報とGit LFS、初期ブランチ名を `~/.config/git/config` に設定します。
初回適用・再適用時には、[移行スクリプト](../home/common/migrate-git-config.sh)が既存の `~/.gitconfig` に直接書かれた
`user.name`、`user.email`、`init.defaultBranch` だけを整理します。

変更前の内容は `~/.gitconfig.before-dotfiles.XXXXXX` に保存し、認証・署名・alias・`include` / `includeIf` は保持します。
include先やリポジトリ固有の設定は変更しません。変更対象がなければ、書き換えやバックアップの追加も行いません。
適用後に既定のGitユーザー情報を変更する場合は、`local.nix` の `git.name` / `git.email` を編集して再適用します。

既存ファイルの退避にはHome Managerの `.backup` 設定を使います
（macOSは `backupFileExtension = "backup"`、Linux/WSLは `switch -b backup`）。
既存のXDG側の設定が退避された場合、退避だけで認証・署名・includeなどが引き続き有効になるとは限りません。
必要な設定はバックアップと照合し、適用後も有効な形で保持してください。

## スクリプトの直接実行

Makefileは既存処理を呼ぶ入口です。OS判定や設定の生成・適用は、引き続き各スクリプトが担当します。
スクリプトは `scripts/` にまとめています。以下のコマンド例はリポジトリルートで実行します。

### init-local.sh

マシン固有の `local.nix` を生成します。
platform、system、username、hostname、home directory、WSL判定、globalのGitユーザー情報を検出します。

```bash
./scripts/init-local.sh
```

対応する組み合わせは `darwin` / `aarch64-darwin` と `linux` / `x86_64-linux` です。
保存先と `--force` の扱いは [local.nix](#localnix) を参照してください。

### bootstrap.sh

初回適用用です。Nixと生成済みの `local.nix` が必要です。

```bash
./scripts/bootstrap.sh
```

macOSではflake inputのnix-darwin、Linux/WSLではflake inputのHome Managerを `nix run` で呼び出します。
`--inputs-from .` によりこのリポジトリのinputsを参照し、`--impure` とともに実行します。
Nixの呼び出しには `--extra-experimental-features nix-command` と `--extra-experimental-features flakes` を明示しています。

### rebuild.sh

設定変更後の日常的な再適用用です。`make rebuild` と同じ処理です。

```bash
./scripts/rebuild.sh
```

`local.nix` の `platform` に応じて次を実行します。

```text
macOS:     darwin-rebuild switch --impure --flake ".#<hostname>"
Linux/WSL: home-manager switch -b backup --extra-experimental-features "nix-command flakes" --impure --flake ".#<username>@<hostname>"
```

bootstrap後の `darwin-rebuild`（macOS）または `home-manager`（Linux/WSL）が必要です。
見つからない場合はエラーで停止します。初回適用直後なら、新しいターミナルで再実行してください。

`bootstrap.sh` と `rebuild.sh` は設定を読む `nix eval` にも上記の実験的機能と `--impure` を指定します。
Linux/WSLではHome Managerの `switch` にも実験的機能の指定を渡します。
どちらも `DOTFILES_LOCAL_NIX` を引き継ぎ、macOSでは `sudo --preserve-env=DOTFILES_LOCAL_NIX` で管理者権限の処理へ渡します。

## inputsの更新

更新はリポジトリ内で実行し、目的に応じてどちらか一方を選びます。
どちらも `flake.lock` の更新までで、再適用・GC・コミットは自動実行しません。

| コマンド | 更新範囲 |
| --- | --- |
| `make update-nixpkgs` | Nixpkgsのみ |
| `make update-all` | Home Manager・nix-darwin・Fenixなどを含む全inputs |

Nixpkgs限定更新ではHome Manager・nix-darwin・Fenix自身のrevisionは更新されません。
ただし、これらは [flake.nix](../flake.nix) の `follows = "nixpkgs"` でNixpkgsを共有するため、その依存先には更新が反映されます。

ソース内でバージョンを直接固定した独自パッケージは、全inputsを更新しても固定値が自動変更されません。
現在の例は [pkgs/nodejs-bin.nix](../pkgs/nodejs-bin.nix) のNode.js `24.22.1` と取得ハッシュです。

makeがない場合の内部コマンドは次のとおりです。
既存スクリプトと同様、`nix-command` と `flakes` を明示的に有効化します。

```bash
# Nixpkgsのみ更新
nix --extra-experimental-features nix-command \
  --extra-experimental-features flakes flake update nixpkgs
```

```bash
# または、全inputsを更新
nix --extra-experimental-features nix-command \
  --extra-experimental-features flakes flake update
```

選んだ更新の後は差分を確認し、問題がなければ設定を反映します。

```bash
git diff -- flake.lock
make rebuild  # makeがなければ ./scripts/rebuild.sh
```

保存先を変更している場合は、再適用で同じ `DOTFILES_LOCAL_NIX` を指定します（[指定例](#localnix)）。
