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
      unset STARSHIP_SHELL
      unset STARSHIP_SESSION_KEY

      setopt PROMPT_SUBST

      function _editor_git_prompt() {
        local status first branch line
        local staged=0
        local unstaged=0
        local untracked=0
        local ahead=""
        local behind=""
        local flags=""

        GIT_PROMPT=""

        status="$(${pkgs.git}/bin/git status --porcelain=v1 --branch 2>/dev/null)" || return

        first="''${status%%$'\n'*}"
        branch="''${first#\#\# }"
        branch="''${branch%%...*}"

        if [[ "$branch" == HEAD* ]]; then
          branch="$(${pkgs.git}/bin/git rev-parse --short HEAD 2>/dev/null)"
        fi

        if [[ "$first" =~ 'ahead ([0-9]+)' ]]; then
          ahead="↑$match[1]"
        fi

        if [[ "$first" =~ 'behind ([0-9]+)' ]]; then
          behind="↓$match[1]"
        fi

        for line in "''${(@f)status}"; do
          [[ "$line" == "## "* ]] && continue

          if [[ "$line" == "?? "* ]]; then
            untracked=1
            continue
          fi

          [[ "''${line[1,1]}" != " " ]] && staged=1
          [[ "''${line[2,2]}" != " " ]] && unstaged=1
        done

        [[ $staged -eq 1 ]] && flags+="+"
        [[ $unstaged -eq 1 ]] && flags+="*"
        [[ $untracked -eq 1 ]] && flags+="?"

        GIT_PROMPT=" %F{green}on  $branch%f"

        if [[ -n "$ahead$behind" ]]; then
          GIT_PROMPT+=" %F{cyan}$ahead$behind%f"
        fi

        if [[ -n "$flags" ]]; then
          GIT_PROMPT+=" %F{yellow}$flags%f"
        fi
      }

      autoload -Uz add-zsh-hook
      add-zsh-hook precmd _editor_git_prompt

      PROMPT='%F{cyan}%~%f''${GIT_PROMPT} %# '
    fi
  '';
}
