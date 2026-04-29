{pkgs, ...}: {
  home.packages = with pkgs; [
    # Runtime
    nodejs_22
    uv

    # Git / GitHub
    gh
    git-lfs

    # CLI tools
    ripgrep
    fd
    eza
    bat
    jq
    tree
    curl
    wget
    unzip
    fastfetch

    # Fonts
    nerd-fonts.hack
  ];
}
