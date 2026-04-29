{
  lib,
  ...
}: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initContent = lib.mkMerge [
      # compinit より前に Docker 補完のパスを追加する
      (lib.mkOrder 550 ''
        # PATH / fpath の重複を削除する
        typeset -U path fpath

        if [ -d "$HOME/.docker/completions" ]; then
          fpath=("$HOME/.docker/completions" $fpath)
        fi
      '')

      # 通常の zsh 初期化
      (lib.mkOrder 1000 ''
        bindkey -e

        export EDITOR="code --wait"
        export VISUAL="code --wait"

        # Nix / nix-darwin / Home Manager のコマンドを優先する
        if [ -d "/etc/profiles/per-user/$USER/bin" ]; then
          path=("/etc/profiles/per-user/$USER/bin" $path)
        fi

        if [ -d "/run/current-system/sw/bin" ]; then
          path=("/run/current-system/sw/bin" $path)
        fi

        # Homebrew は GUI アプリや補助ツール用として残す
        # Nix の後ろに置く
        if [ -d "/opt/homebrew/bin" ]; then
          path=($path "/opt/homebrew/bin")
        fi

        export PATH
      '')
    ];
  };
}
