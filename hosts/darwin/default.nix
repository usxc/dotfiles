{
  username,
  ...
}: {
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

  nixpkgs.hostPlatform = "aarch64-darwin";

  system = {
    stateVersion = 6;
    primaryUser = username;
  };

  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  programs.zsh.enable = true;

  security.pam.services.sudo_local.touchIdAuth = true;
}
