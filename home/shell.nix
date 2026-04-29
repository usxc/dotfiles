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
      (lib.mkOrder 550 ''
        if [ -d "$HOME/.docker/completions" ]; then
          fpath=("$HOME/.docker/completions" $fpath)
        fi
      '')

      ''
        bindkey -e

        export EDITOR="code --wait"
        export VISUAL="code --wait"

        if [ -d "$HOME/.codeium/windsurf/bin" ]; then
          export PATH="$HOME/.codeium/windsurf/bin:$PATH"
        fi

        if [ -d /opt/homebrew/bin ]; then
          export PATH="$PATH:/opt/homebrew/bin"
        fi
      ''
    ];
  };
}
