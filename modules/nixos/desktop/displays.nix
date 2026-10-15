{
  config,
  pkgs,
  lib,
  ...
}:
let
  internal = "eDP-1";
  external = "n/^(DP|HDMI|USB)-";

  hyprMonitor =
    args:
    "${config.programs.hyprland.package}/bin/hyprctl eval \"hl.monitor({output='$SHIKANE_OUTPUT_NAME',mode='preferred',scale=1,${args}})\"";

  displayMode = pkgs.writeShellApplication {
    name = "display-mode";
    runtimeInputs = [
      config.programs.hyprland.package
      pkgs.jq
      pkgs.shikane
    ];
    text = ''
      mode=''${1:-toggle}
      if [ "$mode" = toggle ]; then
        if hyprctl -j monitors all | jq -e 'any(.[]; .mirrorOf != "none")' >/dev/null; then
          mode=extend
        else
          mode=present
        fi
      fi
      case "$mode" in
        extend | present | laptop) exec shikanectl switch "$mode" ;;
        *)
          echo "usage: display-mode [toggle|extend|present|laptop]" >&2
          exit 1
          ;;
      esac
    '';
  };
in
lib.mkIf (config.desktop.enable && config.desktop.environment == "hyprland") {
  environment.systemPackages = [
    displayMode
    pkgs.wdisplays
  ];

  home-manager.sharedModules = [
    {
      # First matching profile wins on hotplug; `present` is only reached via display-mode.
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
        ];
      };
    }
  ];
}
