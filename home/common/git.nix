{
  config,
  gitUser,
  lib,
  pkgs,
  ...
}:
let
  migrateGitConfig = pkgs.writeShellApplication {
    name = "dotfiles-migrate-git-config";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.git
    ];
    text = builtins.readFile ./migrate-git-config.sh;
  };
in
{
  programs.git = {
    enable = true;

    lfs.enable = true;

    settings = {
      user = {
        name = gitUser.name;
        email = gitUser.email;
      };

      init = {
        defaultBranch = "main";
      };
    };
  };

  home.activation.migrateLegacyGitConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    run ${lib.getExe migrateGitConfig} \
      ${lib.escapeShellArg "${config.home.homeDirectory}/.gitconfig"} \
      ${lib.escapeShellArg "${config.xdg.configHome}/git/config"}
  '';
}
