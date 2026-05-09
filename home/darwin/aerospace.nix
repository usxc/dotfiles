{
  ...
}:

let
  aerospaceConfigPath = ../../configs/aerospace/aerospace.toml;

  aerospaceSettings =
    if builtins.pathExists aerospaceConfigPath then
      builtins.fromTOML (builtins.readFile aerospaceConfigPath)
    else
      { };
in
{
  xdg.enable = true;

  programs.aerospace = {
    enable = true;

    launchd = {
      enable = true;
      keepAlive = true;
    };

    settings =
      aerospaceSettings
      // {
        # Home Manager controls launching via launchd.
        start-at-login = false;

        # Use after-startup-command instead if needed.
        after-login-command = [ ];
      };
  };
}
