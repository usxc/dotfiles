{
  pkgs,
  ...
}:
{
  # Applied to:
  # - Apple Silicon macOS only
  #
  # Put macOS-only packages here.
  home.packages = with pkgs; [

  ];
}
