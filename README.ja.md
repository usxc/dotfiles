# dotfiles

[English](README.md) | [日本語](README.ja.md)

Apple Silicon macOS と x86_64 Linux / WSL 用の個人 dotfiles です。

このリポジトリでは Nix flakes、macOS では nix-darwin、macOS と Linux の両方で Home Manager を使っています。

## Initial Setup

### macOS

#### 1. Nix をインストールする

Nix がまだ入っていない場合は、先に Nix をインストールします。

flakes を有効化して Nix modern installer を実行します。

```bash
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes
```

インストーラーは、システムへ変更を加える前に確認を求めることがあります。
`Proceed? ([Y]es/[n]o/[e]xplain)` と表示されたら、Enter または `y` を入力します。

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

#### 3. Git を設定する

`./init-local.sh` は global の Git ユーザー名とメールアドレスを読み取り、`local.nix` に書き込みます。

現在の値を確認します。

```bash
git config --global user.name
git config --global user.email
```

未設定の場合は、先に設定します。

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

#### 4. `local.nix` を作成する

マシン固有の設定を生成します。

```bash
./init-local.sh
```

デフォルトでは、次の場所に作成されます。

```text
~/.config/dotfiles/local.nix
```

Apple Silicon macOS では、生成される内容は次のようになります。

```nix
{
  username = "your-macos-username";
  hostname = "your-mac";

  platform = "darwin";
  system = "aarch64-darwin";
  homeDirectory = "/Users/your-macos-username";

  git = {
    name = "Your Name";
    email = "you@example.com";
  };
}
```

`local.nix` はマシン固有の設定です。Git にはコミットしません。

別の場所に作成したい場合は、スクリプト実行時に `DOTFILES_LOCAL_NIX` を指定します。

```bash
DOTFILES_LOCAL_NIX=/path/to/local.nix ./init-local.sh
```

#### 5. nix-darwin を初回適用する

初回の nix-darwin activation を実行します。

```bash
./bootstrap.sh
```

これで nix-darwin のシステム設定と Home Manager のユーザー設定が適用されます。

以降の日常的な更新には `./rebuild.sh` を使います。

### Linux / WSL

#### 1. Nix をインストールする

Nix がまだ入っていない場合は、先に Nix をインストールします。

flakes を有効化して Nix modern installer を実行します。

```bash
curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes
```

インストール後、shell を開き直します。

Nix が使えることを確認します。

```bash
nix --version
```

#### 2. リポジトリを clone する

```bash
git clone https://github.com/usxc/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

#### 3. Git を設定する

`./init-local.sh` は global の Git ユーザー名とメールアドレスを読み取り、`local.nix` に書き込みます。

現在の値を確認します。

```bash
git config --global user.name
git config --global user.email
```

未設定の場合は、先に設定します。

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

#### 4. `local.nix` を作成する

マシン固有の設定を生成します。

```bash
./init-local.sh
```

x86_64 Linux / WSL では、生成される内容は次のようになります。

```nix
{
  username = "your-linux-username";

  # Linux ホスト名、または WSL ディストリビューション名によって変わります。
  # 例: "ubuntu", "debian", "arch", "my-linux"
  hostname = "ubuntu";

  platform = "linux";
  system = "x86_64-linux";
  homeDirectory = "/home/your-linux-username";

  isWsl = true;

  git = {
    name = "Your Name";
    email = "you@example.com";
  };
}
```

`isWsl = true;` は WSL を検出した場合だけ生成されます。

Linux の出力名は次の形式です。

```text
homeConfigurations.<username>@<hostname>
```

#### 5. Home Manager を初回適用する

初回の Home Manager activation を実行します。

```bash
./bootstrap.sh
```

これで flake input の Home Manager を使って Linux / WSL のユーザー設定が適用されます。

以降の日常的な更新には `./rebuild.sh` を使います。

#### 6. zsh をログインシェルにする

Linux / WSL では、Home Manager によって zsh の設定は作成されます。

ただし、ログインシェル自体は自動で zsh に変わらない場合があります。

`./bootstrap.sh` の後に、次を一度だけ実行します。

```bash
ZSH_PATH="$(command -v zsh)"

if [ -z "$ZSH_PATH" ]; then
  echo "zsh not found"
  exit 1
fi

if ! grep -qxF "$ZSH_PATH" /etc/shells; then
  echo "$ZSH_PATH" | sudo tee -a /etc/shells
fi

chsh -s "$ZSH_PATH"
```

WSL の場合は、PowerShell 側で WSL を再起動します。

```powershell
wsl --shutdown
```

その後、Linux / WSL を開き直して確認します。

```bash
echo "$SHELL"
```

`zsh` が含まれていれば OK です。

以降の日常的な更新には `./rebuild.sh` を使います。

## Daily Usage

設定変更を反映します。

```bash
cd ~/dotfiles
./rebuild.sh
```

`./rebuild.sh` は `local.nix` を読み、`platform` に応じて次を実行します。

```text
macOS:      darwin-rebuild switch --impure --flake ".#<hostname>"
Linux/WSL: home-manager switch --impure --flake ".#<username>@<hostname>"
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
├── README.md                 # 英語 README
├── README.ja.md              # 日本語 README
├── flake.nix                 # flake エントリーポイント
├── flake.lock                # 固定された flake inputs
├── local.nix.example         # マシン固有設定の例
├── init-local.sh             # local.nix 生成
├── bootstrap.sh              # 初回適用
├── rebuild.sh                # 日常的な rebuild
├── .gitignore
├── hosts/
│   └── darwin/
│       └── default.nix       # nix-darwin システム設定
├── home/
│   ├── common/               # 共通 Home Manager モジュール
│   │   ├── default.nix       # 共通 Home Manager エントリーポイント
│   │   ├── packages.nix      # 共通パッケージと開発ツール
│   │   ├── git.nix           # Git
│   │   ├── shell.nix         # Zsh
│   │   └── prompt.nix        # Starship
│   ├── darwin/               # macOS 専用 Home Manager モジュール
│   │   ├── default.nix       # macOS Home Manager エントリーポイント
│   │   ├── packages.nix      # macOS パッケージ
│   │   ├── aerospace.nix     # AeroSpace
│   │   └── terminals.nix     # Ghostty 設定リンク
│   └── linux/                # Linux / WSL Home Manager モジュール
│       ├── default.nix       # Linux Home Manager エントリーポイント
│       ├── packages.nix      # Linux パッケージ
│       ├── session.nix       # Linux session variables
│       └── wsl.nix           # WSL
└── configs/
    ├── ghostty/
    │   └── config.ghostty    # Ghostty 設定
    └── aerospace/
        └── aerospace.toml    # AeroSpace 設定
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
