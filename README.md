# dotfiles

Apple Silicon macOS と x86_64 Linux / WSL 用の dotfiles です。

## Initial Setup

macOS・Linux・WSLで共通の手順です。Gitとcurlを事前に用意してください。

### 1. Nixを準備する

Nixが未導入の場合は、flakesを有効にしてインストールします。

WSLの場合は、先に[WSLの準備](docs/setup.md#wsl)を確認してください。

```bash
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes
```

インストール後はターミナルを開き直し、Nixが使えることを確認します。

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

```bash
git config --global user.name
git config --global user.email
```

未設定の項目があれば、自分の情報を登録してください。

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

### 4. 設定を生成して適用する

```bash
./init-local.sh && ./bootstrap.sh
```

ユーザー名・ホスト名・Git情報などから、
`~/.config/dotfiles/local.nix` を生成します。このファイルはGit管理に含めません。

設定例は [local.nix.example](local.nix.example)、
保存先の変更方法は[セットアップの補足](docs/setup.md#localnix)を参照してください。

macOSではnix-darwinとHome Manager、Linux/WSLではHome Managerの設定が適用されます。
macOSでは管理者認証が必要です。

適用後はターミナルを開き直してください。
Linux/WSLでは、[ログインシェルをzshに変更する手順](docs/setup.md#zsh)も確認してください。

## Daily Usage

設定変更を反映します。

```bash
cd ~/dotfiles
./rebuild.sh
```

`./rebuild.sh` は `local.nix` を読み、`platform` に応じて次を実行します。

```text
macOS:      darwin-rebuild switch --impure --flake ".#<hostname>"
Linux/WSL: home-manager switch -b backup --impure --flake ".#<username>@<hostname>"
```

flake inputs を更新します。

```bash
cd ~/dotfiles
nix flake update
./rebuild.sh
```

`local.nix` がデフォルト以外の場所にある場合は、日常的なコマンドでも同じパスを指定します。

```bash
DOTFILES_LOCAL_NIX=/path/to/local.nix ./rebuild.sh
```

## Scripts

### `init-local.sh`

マシン固有の `local.nix` を生成します。

platform、system、username、hostname、home directory、WSL 判定、global の Git ユーザー情報を検出します。

```bash
./init-local.sh
```

既存の生成済みファイルを上書きする場合は `--force` を使います。

```bash
./init-local.sh --force
```

### `bootstrap.sh`

初回適用用です。

macOS では flake input の nix-darwin を使って bootstrap します。Linux / WSL では flake input の Home Manager を使って bootstrap します。

```bash
./bootstrap.sh
```

### `rebuild.sh`

設定を編集した後の日常的な rebuild 用です。

macOS では bootstrap 後に `darwin-rebuild` が使えることを前提にします。Linux / WSL では bootstrap 後に `home-manager` が使えることを前提にします。

```bash
./rebuild.sh
```

## Structure

```text
.
├── README.md                 # 日本語 README
├── flake.nix                 # flake エントリーポイント
├── flake.lock                # 固定された flake inputs
├── local.nix.example         # マシン固有設定の例
├── init-local.sh             # local.nix 生成
├── bootstrap.sh              # 初回適用
├── rebuild.sh                # 日常的な rebuild
├── .gitignore
├── docs/
│   └── setup.md              # セットアップの補足
├── pkgs/
│   └── nodejs-bin.nix        # Node.js の独自パッケージ定義
├── hosts/
│   └── darwin/
│       └── default.nix       # nix-darwin システム設定
├── home/
│   ├── common/               # 共通 Home Manager モジュール
│   │   ├── default.nix       # 共通 Home Manager エントリーポイント
│   │   ├── packages.nix      # 共通パッケージと開発ツール
│   │   ├── git.nix           # Git
│   │   ├── shell.nix         # Zsh
│   │   ├── direnv.nix        # direnv
│   │   └── prompt.nix        # Starship
│   ├── darwin/               # macOS 専用 Home Manager モジュール
│   │   ├── default.nix       # macOS Home Manager エントリーポイント
│   │   ├── packages.nix      # macOS パッケージ
│   │   └── terminals.nix     # Ghostty 設定リンク
│   └── linux/                # Linux / WSL Home Manager モジュール
│       ├── default.nix       # Linux Home Manager エントリーポイント
│       ├── packages.nix      # Linux パッケージ
│       ├── session.nix       # Linux session variables
│       └── wsl.nix           # WSL
└── configs/
    └── ghostty/
        └── config.ghostty    # Ghostty 設定
```

## Requirements

### macOS

- Apple Silicon Mac
- Git
- Nix

### Linux / WSL

- x86_64 Linux or WSL
- Git
- Nix
