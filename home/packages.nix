{pkgs, ...}: {
  home.packages = with pkgs; [
    # Runtime
    nodejs_22
    bun
    pnpm

    # Nix
    nixd
    nixfmt-rfc-style
    
    # Python
    uv

    # Ruby
    rbenv
    ruby-build

    # Rust
    (fenix.stable.withComponents [
      "cargo"
      "clippy"
      "rust-src"
      "rustc"
      "rustfmt"
    ])
    rust-analyzer

    # Typescript
    typescript-language-server

    # Lua
    lua5_5
    lua-language-server
    stylua

    # Database
    sqlite

    # Git / GitHub
    gh
    git-lfs

    # CLI tools
    ripgrep
    fd
    eza
    bat
    jq
    yq-go
    fzf
    difftastic
    tree
    curl
    wget
    unzip
    fastfetch

    # Desktop Apps
    aerospace

    # Fonts
    nerd-fonts.hack
  ];
}
