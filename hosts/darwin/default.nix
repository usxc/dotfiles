{
  username,
  homeDirectory,
  local,
  ...
}:
{
  nix = {
    enable = true;

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];

      trusted-users = [
        "root"
        username
      ];
    };
  };

  nixpkgs.hostPlatform = local.system;

  system = {
    stateVersion = 6;
    primaryUser = username;
  };

  users.users.${username} = {
    name = username;
    home = homeDirectory;
  };

  programs.zsh.enable = true;

  security.pam.services.sudo_local.touchIdAuth = true;
}
