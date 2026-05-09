{
  pkgs,
  ...
}:
{
  # Applied to:
  # - WSL only
  #
  # Put WSL-specific packages and settings here.
  home.packages = with pkgs; [
    # WSL utilities
    wsl-open
  ];

  # Use Windows default browser from WSL.
  home.sessionVariables = {
    BROWSER = "wsl-open";
  };
}
