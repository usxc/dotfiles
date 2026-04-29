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
        if [ -d "$HOME/.docker/completions" ]; then
          fpath=("$HOME/.docker/completions" $fpath)
        fi
      '')

      # 通常の zsh 初期化
      (lib.mkOrder 1000 ''
        bindkey -e

        export EDITOR="code --wait"
        export VISUAL="code --wait"

        # Nix / nix-darwin / Home Manager のコマンドを最優先にする
        if [ -d "/etc/profiles/per-user/$USER/bin" ]; then
          export PATH="/etc/profiles/per-user/$USER/bin:$PATH"
        fi

        if [ -d "/run/current-system/sw/bin" ]; then
          export PATH="/run/current-system/sw/bin:$PATH"
        fi

        if [ -d "$HOME/.nix-profile/bin" ]; then
          export PATH="$HOME/.nix-profile/bin:$PATH"
        fi

        # Windsurf
        if [ -d "$HOME/.codeium/windsurf/bin" ]; then
          export PATH="$HOME/.codeium/windsurf/bin:$PATH"
        fi

        # Homebrew は GUI アプリや補助ツール用として残す
        # Nix の後ろに置く
        if [ -d "/opt/homebrew/bin" ]; then
          export PATH="$PATH:/opt/homebrew/bin"
        fi
      '')
    ];
  };
}
