{
  pkgs,
  ...
}:
{
  # Applied to:
  # - x86_64 Linux
  # - WSL
  #
  # Put Linux-specific packages here.
  home.packages = with pkgs; [
    # Build tools
    gcc
    gnumake
    pkg-config
    openssl

    # Security
    gnupg

    # Archive
    zip

    # CLI tools
    file
    which
  ];
}
