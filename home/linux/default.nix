{
  lib,
  local,
  ...
}:
{
  imports =
    [
      ./packages.nix
      ./session.nix
    ]
    ++ lib.optionals (local.isWsl or false) [
      ./wsl.nix
    ];

  # Useful for non-NixOS Linux distributions such as Ubuntu or WSL Ubuntu.
  targets.genericLinux.enable = true;

  # bash is intentionally not managed.
  # zsh is managed in home/common/shell.nix.
}
