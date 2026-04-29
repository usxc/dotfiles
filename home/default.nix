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

  programs.home-manager.enable = true;
}
