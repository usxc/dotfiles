{
  username,
  ...
}: {
  imports = [
    ./packages.nix
    ./git.nix
    ./shell.nix
    ./prompt.nix
    ./terminals.nix
  ];

  home = {
    username = username;
    homeDirectory = "/Users/${username}";
    stateVersion = "25.11";
  };

  xdg.configFile = {
    "aerospace/aerospace.toml".source = ../configs/aerospace/aerospace.toml;
  };

  programs.home-manager.enable = true;
}
