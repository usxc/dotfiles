{
  lib,
  local,
  ...
}:
{
  # Applied to:
  # - x86_64 Linux
  # - WSL
  #
  # Put Linux session environment variables here.
  #
  # Do not put EDITOR or VISUAL here.
  # They are configured in home/common/shell.nix
  # with fallback: code -> vim -> vi.
  home.sessionVariables =
    {
      DOTFILES_PLATFORM = "linux";
    }
    // lib.optionalAttrs (local.isWsl or false) {
      DOTFILES_IS_WSL = "1";
    };
}
