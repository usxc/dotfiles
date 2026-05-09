{
  pkgs,
  ...
}:
{
  # Applied to:
  # - Apple Silicon macOS
  # - x86_64 Linux
  # - WSL
  #
  # Put packages here when they are useful on every supported environment.
  home.packages = with pkgs; [
    # Runtimes
    nodejs_24
    bun
    pnpm
    uv

    # Language version manager
    mise

    # Nix
    nixd
    nixfmt

    # Rust
    (fenix.stable.withComponents [
      "cargo"
      "clippy"
      "rust-src"
      "rustc"
      "rustfmt"
    ])
    rust-analyzer

    # TypeScript
    typescript-language-server

    # Lua
    lua5_4
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
    vim

    # Fonts
    nerd-fonts.hack
  ];
}
