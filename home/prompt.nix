{ lib, pkgs, ... }: {
  programs.starship = {
    enable = true;

    # Home Manager に無条件で starship init を書かせない
    enableZshIntegration = false;

    settings = {
      "$schema" = "https://starship.rs/config-schema.json";

      command_timeout = 2000;
      
      python = {
        python_binary = "python3";
      };

      cmd_duration = {
        min_time = 1000;
      };
    };
  };

  programs.zsh.initContent = lib.mkOrder 1200 ''
    # Initialize starship except in editor terminals
    if [[ "$TERM_PROGRAM" != "vscode" ]] && [[ "$TERM_PROGRAM" != "cursor" ]] && [[ -z "$ZED_TERM" ]]; then
      eval "$(${pkgs.starship}/bin/starship init zsh)"
    else
      PROMPT='%F{cyan}%~%f %# '
    fi
  '';
}
