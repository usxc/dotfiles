{
  lib,
  pkgs,
  ...
}:

let
  aerospaceConfigPath = ../../configs/aerospace/aerospace.toml;
  aerospace = lib.getExe pkgs.aerospace;

  aerospaceSettings =
    if builtins.pathExists aerospaceConfigPath then
      builtins.fromTOML (builtins.readFile aerospaceConfigPath)
    else
      { };

  afterStartupCommands = lib.lists.remove "enable off" (
    aerospaceSettings."after-startup-command" or [ ]
  );
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
      after-startup-command = afterStartupCommands ++ [ "enable off" ];
    };
  };

  home.file."/.config/aerospace/aerospace.toml".onChange = lib.mkForce ''
    echo "AeroSpace config changed, reloading..."

    if reload_output="$(${aerospace} reload-config 2>&1)"; then
      :
    else
      reload_status=$?

      case "$reload_output" in
        *"server is disabled"*)
          echo "AeroSpace is disabled; temporarily enabling it to reload config..."

          (
            restore_disabled=false

            restore_aerospace_disabled() {
              if [ "$restore_disabled" = true ]; then
                ${aerospace} enable off >/dev/null 2>&1 || true
              fi
            }

            trap restore_aerospace_disabled EXIT

            restore_disabled=true
            ${aerospace} enable on
            ${aerospace} reload-config
            ${aerospace} enable off
            restore_disabled=false
          )
          ;;
        *"Can't connect to AeroSpace server"*)
          echo "AeroSpace is not running; skipping reload."
          ;;
        *)
          printf '%s\n' "$reload_output" >&2
          exit "$reload_status"
          ;;
      esac
    fi
  '';
}
