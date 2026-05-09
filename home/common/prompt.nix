{
  lib,
  pkgs,
  ...
}:
{
  programs.starship = {
    enable = true;

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
    # Avoid inherited starship env in editor terminals
    if [[ "$TERM_PROGRAM" == "vscode" ]] || [[ "$TERM_PROGRAM" == "cursor" ]] || [[ -n "$ZED_TERM" ]]; then
      unset STARSHIP_SHELL
      unset STARSHIP_SESSION_KEY
    fi

    # Initialize starship except in editor terminals
    if [[ "$TERM_PROGRAM" != "vscode" ]] && [[ "$TERM_PROGRAM" != "cursor" ]] && [[ -z "$ZED_TERM" ]]; then
      eval "$(${pkgs.starship}/bin/starship init zsh)"
    fi
  '';
}
