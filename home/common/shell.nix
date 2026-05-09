{
  config,
  lib,
  local,
  ...
}:
{
  programs.zsh = {
    enable = true;
    dotDir = config.home.homeDirectory;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    initContent = lib.mkMerge [
      (lib.mkOrder 550 ''
        # Remove duplicate PATH and fpath entries
        typeset -U path fpath

        if [ -d "$HOME/.docker/completions" ]; then
          fpath=("$HOME/.docker/completions" $fpath)
        fi
      '')

      (lib.mkOrder 1000 ''
        bindkey -e

        if command -v code >/dev/null 2>&1; then
          export EDITOR="code --wait"
          export VISUAL="code --wait"
        elif command -v vim >/dev/null 2>&1; then
          export EDITOR="vim"
          export VISUAL="vim"
        else
          export EDITOR="vi"
          export VISUAL="vi"
        fi

        # Home Manager user profile
        if [ -d "$HOME/.nix-profile/bin" ]; then
          path=("$HOME/.nix-profile/bin" $path)
        fi

        # nix-darwin per-user profile
        if [ -d "/etc/profiles/per-user/$USER/bin" ]; then
          path=("/etc/profiles/per-user/$USER/bin" $path)
        fi

        # Nix daemon profile
        if [ -d "/nix/var/nix/profiles/default/bin" ]; then
          path=("/nix/var/nix/profiles/default/bin" $path)
        fi

        # nix-darwin / NixOS system profile
        if [ -d "/run/current-system/sw/bin" ]; then
          path=("/run/current-system/sw/bin" $path)
        fi

        ${lib.optionalString (local.platform == "darwin") ''
          # Homebrew on Apple Silicon
          if [ -d "/opt/homebrew/bin" ]; then
            path=($path "/opt/homebrew/bin")
          fi
        ''}

        export PATH

        # mise
        if command -v mise >/dev/null 2>&1; then
          eval "$(mise activate zsh)"
        fi
      '')
    ];
  };
}
