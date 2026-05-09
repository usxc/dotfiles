{
  lib,
  local,
  pkgs,
  ...
}:
{
  programs.starship = {
    enable = true;

    # Initialize starship manually in zsh.
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
    # Detect editor integrated terminals
    is_editor_terminal=false

    if [[ "''${TERM_PROGRAM:-}" == "vscode" ]] \
      || [[ "''${TERM_PROGRAM:-}" == "cursor" ]] \
      || [[ -n "''${CURSOR_TRACE_ID:-}" ]] \
      || [[ -n "''${ZED_TERM:-}" ]]; then
      is_editor_terminal=true
    fi

    # Avoid inherited starship environment in editor terminals
    if [[ "$is_editor_terminal" == "true" ]]; then
      unset STARSHIP_SHELL
      unset STARSHIP_SESSION_KEY

      ${lib.optionalString (local.platform == "linux") ''
        # Ubuntu bash-like prompt for Linux / WSL editor terminals
        if [[ -z "''${debian_chroot:-}" && -r /etc/debian_chroot ]]; then
          debian_chroot="$(cat /etc/debian_chroot)"
        fi

        debian_chroot_prompt=""
        if [[ -n "''${debian_chroot:-}" ]]; then
          debian_chroot_prompt="(''${debian_chroot})"
        fi

        PROMPT="''${debian_chroot_prompt}%B%F{green}%n@%m%f%b:%B%F{blue}%~%f%b%(!.#.$) "
        RPROMPT=""
      ''}
    fi

    # Initialize starship except in editor terminals
    if [[ "$is_editor_terminal" != "true" ]]; then
      eval "$(${pkgs.starship}/bin/starship init zsh)"
    fi
  '';
}
