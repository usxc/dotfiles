{
  description = "usxc's dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    ...
  }: let
    system = "aarch64-darwin";

    localPath = builtins.getEnv "DOTFILES_LOCAL_NIX";

    local =
      if localPath == ""
      then throw "Set DOTFILES_LOCAL_NIX and run with --impure."
      else import localPath;

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    homeConfigurations.${local.username} =
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs;

        modules = [
          ./home
        ];

        extraSpecialArgs = {
          username = local.username;
          gitUser = local.git;
        };
      };
  };
}
