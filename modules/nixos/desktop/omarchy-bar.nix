{
  config,
  lib,
  pkgs,
  ...
}:
let
  c = config.theming.colors;
  omarchy = pkgs.omarchy-shell.override {
    excludePlugins = [
      "background"
      "clipboard"
      "dev-gallery"
      "dock"
      "emojis"
      "image-picker"
      "lock"
      "notifications"
      "osd"
      "polkit"
      "reminders"
      "services/idle"
    ];
  };
  defaults = lib.importJSON "${omarchy}/config/omarchy/shell.json";
  barIpc = "-${lib.getExe' pkgs.quickshell "qs"} -c bar ipc call bar";
in
{
  options.desktop.omarchyBar.enable = lib.mkEnableOption "the Omarchy shell bar as an alternative to the quickshell bar";

  config = lib.mkIf (config.desktop.omarchyBar.enable && config.desktop.environment == "hyprland") {
    # Swap: `systemctl --user start omarchy-bar`; back: `systemctl --user stop omarchy-bar`.
    systemd.user.services.omarchy-bar = {
      description = "Omarchy shell bar (experiment)";
      after = [
        "graphical-session.target"
        "quickshell.service"
      ];
      partOf = [ "graphical-session.target" ];
      path = [
        omarchy
        pkgs.inotify-tools
        pkgs.jq
        pkgs.libnotify
      ]
      ++ config.systemd.user.services.quickshell.path;
      environment = {
        OMARCHY_PATH = "${omarchy}";
        QS_DISABLE_FILE_WATCHER = "1";
      };
      serviceConfig = {
        Type = "simple";
        ExecStart = "${lib.getExe' pkgs.quickshell "quickshell"} -n -p ${omarchy}/shell";
        ExecStartPost = "${barIpc} hide";
        ExecStopPost = "${barIpc} reveal";
        Restart = "on-failure";
        RestartSec = "3";
      };
    };

    home-manager.sharedModules = [
      {
        # Omarchy rewrites this file in place when the bar is edited; force reclaims it on switch.
        xdg.configFile."omarchy/shell.json" = {
          force = true;
          source = (pkgs.formats.json { }).generate "shell.json" (
            lib.recursiveUpdate defaults {
              bar.layout.left = builtins.filter (w: w.id != "omarchy.menu") defaults.bar.layout.left;
            }
          );
        };

        xdg.stateFile."omarchy/current/theme/colors.toml".source =
          (pkgs.formats.toml { }).generate "colors.toml"
            {
              background = c.bg;
              foreground = c.fg;
              accent = config.theming.accent;
              muted = c.brightBlack;
              inherit (c) red;
            };
      }
    ];
  };
}
