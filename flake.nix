{
  description = "usxc's dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    nix-darwin,
    home-manager,
    fenix,
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
      overlays = [
        fenix.overlays.default
      ];
      config.allowUnfree = true;
    };
  in {
    darwinConfigurations.${local.hostname} = nix-darwin.lib.darwinSystem {
      inherit system;

      specialArgs = {
        inherit pkgs;
        username = local.username;
      };

      modules = [
        ./hosts/darwin

        home-manager.darwinModules.home-manager

        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";

            users.${local.username} = import ./home;

            extraSpecialArgs = {
              inherit pkgs;
              username = local.username;
              gitUser = local.git;
            };
          };
        }
      ];
    };
  };
}
