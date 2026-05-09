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

  outputs =
    inputs@{
      nixpkgs,
      nix-darwin,
      home-manager,
      fenix,
      ...
    }:
    let
      lib = nixpkgs.lib;

      localPath = builtins.getEnv "DOTFILES_LOCAL_NIX";

      local =
        if localPath == "" then
          throw "Set DOTFILES_LOCAL_NIX and run with --impure."
        else
          import localPath;

      mkPkgs =
        system:
        import nixpkgs {
          inherit system;

          overlays = [
            fenix.overlays.default
          ];

          config.allowUnfree = true;
        };
    in
    if !(
      local ? username
      && local ? hostname
      && local ? platform
      && local ? system
      && local ? homeDirectory
      && local ? git
      && local.git ? name
      && local.git ? email
    ) then
      throw ''
        local.nix is missing required fields.

        Required example:

          {
            username = "your-username";
            hostname = "your-hostname";
            platform = "darwin";
            system = "aarch64-darwin";
            homeDirectory = "/Users/your-username";

            git = {
              name = "Your Name";
              email = "you@example.com";
            };
          }

        For WSL, also add:

          isWsl = true;
      ''
    else
      let
        isDarwin = local.platform == "darwin";
        isLinux = local.platform == "linux";
        isWsl = local.isWsl or false;

        supportedPlatformSystem =
          (local.platform == "darwin" && local.system == "aarch64-darwin")
          || (local.platform == "linux" && local.system == "x86_64-linux");

        commonSpecialArgs = {
          inherit inputs local;

          username = local.username;
          homeDirectory = local.homeDirectory;
          gitUser = local.git;
        };

        homeConfigurationName = "${local.username}@${local.hostname}";
      in
      if !supportedPlatformSystem then
        throw ''
          Unsupported platform/system combination.

          This dotfiles supports only:

            Apple Silicon macOS:
              platform = "darwin";
              system   = "aarch64-darwin";

            x86_64 Linux / WSL:
              platform = "linux";
              system   = "x86_64-linux";

          Unsupported examples:
            platform = "darwin"; system = "x86_64-darwin";
            platform = "linux";  system = "aarch64-linux";
        ''
      else if isWsl && !isLinux then
        throw ''
          Invalid local.nix.

          isWsl can be true only when platform = "linux".

          Correct WSL example:

            platform = "linux";
            system   = "x86_64-linux";
            isWsl    = true;
        ''
      else
        {
          darwinConfigurations = lib.optionalAttrs isDarwin {
            ${local.hostname} =
              nix-darwin.lib.darwinSystem {
                system = local.system;

                specialArgs = commonSpecialArgs;

                modules = [
                  {
                    nixpkgs = {
                      hostPlatform = local.system;

                      overlays = [
                        fenix.overlays.default
                      ];

                      config.allowUnfree = true;
                    };
                  }

                  ./hosts/darwin

                  home-manager.darwinModules.home-manager

                  {
                    home-manager = {
                      useGlobalPkgs = true;
                      useUserPackages = true;
                      backupFileExtension = "backup";

                      users.${local.username} = {
                        imports = [
                          ./home/common
                          ./home/darwin
                        ];
                      };

                      extraSpecialArgs = commonSpecialArgs;
                    };
                  }
                ];
              };
          };

          homeConfigurations = lib.optionalAttrs isLinux {
            ${homeConfigurationName} =
              home-manager.lib.homeManagerConfiguration {
                pkgs = mkPkgs local.system;

                extraSpecialArgs = commonSpecialArgs;

                modules = [
                  ./home/common
                  ./home/linux
                ];
              };
          };
        };
}
