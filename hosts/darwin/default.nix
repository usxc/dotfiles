{
  pkgs,
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

  launchd.user.agents.aerospace = {
    serviceConfig = {
      ProgramArguments = [
        "${pkgs.aerospace}/Applications/AeroSpace.app/Contents/MacOS/AeroSpace"
      ];

      EnvironmentVariables = {
        HOME = "/Users/${username}";
        USER = username;
        PATH = "/etc/profiles/per-user/${username}/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin";
      };

      RunAtLoad = true;
      KeepAlive = true;
    };
  };
}
