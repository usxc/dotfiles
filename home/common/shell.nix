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

        # Nix and Home Manager initialize PATH before .zshrc. Keep inherited
        # project toolchains first, and only add profiles missing from PATH.
        () {
          local profile_dir
          for profile_dir in \
            "/run/current-system/sw/bin" \
            "/nix/var/nix/profiles/default/bin" \
            "/etc/profiles/per-user/$USER/bin" \
            "$HOME/.nix-profile/bin"; do
            if [[ -d "$profile_dir" && ''${path[(Ie)$profile_dir]} -eq 0 ]]; then
              path+=("$profile_dir")
            fi
          done
        }

        ${lib.optionalString (local.platform == "darwin") ''
          # Homebrew on Apple Silicon
          if [ -d "/opt/homebrew/bin" ]; then
            path=($path "/opt/homebrew/bin")
          fi
        ''}

        export PATH

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
      '')
    ];
  };
}
