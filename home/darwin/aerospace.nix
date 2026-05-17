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

    settings = aerospaceSettings // {
      # Home Manager controls launching via launchd.
      start-at-login = false;

      # Do not use AeroSpace's own login hook when launchd manages startup.
      after-login-command = [ ];

      # Start AeroSpace at login, but keep window management disabled initially.
      after-startup-command = [
        "enable off"
      ];
    };
  };
}
