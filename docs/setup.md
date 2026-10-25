# セットアップの補足

基本の手順は [README](../README.md#initial-setup) を参照してください。

## WSL

このREADMEで案内しているNixのインストール方法では、WSL2でsystemdを有効にした環境を使います。
Nixがすでに使える場合は、再インストールせずREADMEの確認手順へ進んでください。

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

再度 `ps -p 1 -o comm=` で確認したら、READMEのNixインストール手順へ戻ります。
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

`./init-local.sh` は、マシン固有の設定を既定では `~/.config/dotfiles/local.nix` に生成します。
生成される項目とOSごとの値は [local.nix.example](../local.nix.example) を参照してください。

既存のファイルは通常の実行では上書きされません。
作り直す場合の `--force` オプションは、READMEの [init-local.sh](../README.md#init-localsh) に記載しています。

保存先を変更する場合は、リポジトリ外のパスを指定します。
`init-local.sh` と `bootstrap.sh` に、同じ `DOTFILES_LOCAL_NIX` を渡してください。

```bash
DOTFILES_LOCAL_NIX=/path/to/local.nix ./init-local.sh &&
DOTFILES_LOCAL_NIX=/path/to/local.nix ./bootstrap.sh
```

以降の再適用でも、同じパスを指定します。

```bash
DOTFILES_LOCAL_NIX=/path/to/local.nix ./rebuild.sh
```
