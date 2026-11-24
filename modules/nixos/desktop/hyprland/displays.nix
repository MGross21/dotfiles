{
  config,
  pkgs,
  lib,
  ...
}:
let
  internal = "eDP-1";
  external = "n/^(DP|HDMI|USB)-";
  plugin = "dotfiles.displays";

  hyprMonitor =
    args:
    "${lib.getExe' config.programs.hyprland.package "hyprctl"} eval \"hl.monitor({output='$SHIKANE_OUTPUT_NAME',mode='preferred',scale=1,${args}})\"";

  displayMode = pkgs.writeShellApplication {
    name = "display-mode";
    runtimeInputs = [
      config.programs.hyprland.package
      pkgs.jq
      pkgs.shikane
    ];
    runtimeEnv = {
      INTERNAL = internal;
      EXTERNAL = lib.removePrefix "n/" external;
    };
    text = builtins.readFile ./display-mode.sh;
  };
in
lib.mkIf (config.desktop.enable && config.desktop.environment == "hyprland") {
  environment.systemPackages = [
    displayMode
    pkgs.wdisplays
  ];

  desktop.omarchy.plugins.${plugin} = lib.mkIf config.desktop.omarchy.enable {
    source = ".config/omarchy/plugins/${plugin}";
    barSection = "right";
    packages = [
      displayMode
      pkgs.wdisplays
    ];
  };

  home-manager.sharedModules = [
    {
      # First matching profile wins on hotplug; later ones are only reached via display-mode.
      services.shikane = {
        enable = true;
        settings.profile = [
          {
            name = "laptop";
            output = [
              {
                search = "n=${internal}";
                enable = true;
              }
            ];
          }
          {
            name = "extend";
            output = [
              {
                search = "n=${internal}";
                enable = true;
                position = "0,0";
              }
              {
                search = external;
                enable = true;
                exec = [ (hyprMonitor "position='1920x0',mirror=''") ];
              }
            ];
          }
          {
            name = "present";
            output = [
              {
                search = "n=${internal}";
                enable = true;
                position = "0,0";
              }
              {
                search = external;
                enable = true;
                exec = [ (hyprMonitor "position='auto',mirror='${internal}'") ];
              }
            ];
          }
          {
            name = "internal";
            output = [
              {
                search = "n=${internal}";
                enable = true;
                position = "0,0";
              }
              {
                search = external;
                enable = false;
              }
            ];
          }
          {
            name = "external";
            output = [
              {
                search = "n=${internal}";
                enable = false;
              }
              {
                search = external;
                enable = true;
                exec = [ (hyprMonitor "position='0x0',mirror=''") ];
              }
            ];
          }
        ];
      };
    }
  ];
}
