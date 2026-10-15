{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  loginctl = "${pkgs.systemd}/bin/loginctl";
  idle = cmd: "${lib.getExe idlectl} ${cmd}";

  idlectl = pkgs.writeShellApplication {
    name = "idlectl";
    runtimeInputs = with pkgs; [
      config.programs.hyprland.package
      config.programs.hyprlock.package
      brightnessctl
      coreutils
      dunst
      gnugrep
      procps
      systemd
    ];
    text = ''
      dpms() {
        hyprctl dispatch "hl.dsp.dpms({ action = \"$1\" })" >/dev/null
      }

      on_ac() {
        for supply in /sys/class/power_supply/*; do
          [ "$(cat "$supply/type" 2>/dev/null)" = Mains ] &&
            [ "$(cat "$supply/online" 2>/dev/null)" = 1 ] && return 0
        done
        return 1
      }

      case "''${1:-}" in
        lock)
          pidof hyprlock >/dev/null && exit 0
          paused=$(dunstctl is-paused 2>/dev/null || echo false)
          dunstctl set-paused true 2>/dev/null || true
          hyprlock -c /etc/hypr/hyprlock.conf || true
          dunstctl set-paused "$paused" 2>/dev/null || true
          ;;
        dim) brightnessctl -q -s set "$(($(brightnessctl get) * 3 / 10))" ;;
        undim) brightnessctl -q -r ;;
        dpms-off) pidof hyprlock >/dev/null && dpms off ;;
        dpms-on) dpms on ;;
        suspend)
          on_ac && exit 0
          systemd-inhibit --list --mode=block --no-legend | grep -qw sleep && exit 0
          systemctl suspend
          ;;
        *)
          echo "usage: idlectl lock|dim|undim|dpms-off|dpms-on|suspend" >&2
          exit 1
          ;;
      esac
    '';
  };

  keepawake = pkgs.writeShellApplication {
    name = "keepawake";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.systemd
    ];
    text = ''
      if [ "$#" -eq 0 ]; then
        set -- sleep infinity
      fi
      exec systemd-inhibit --what=idle:sleep --who=keepawake --why="$*" "$@"
    '';
  };

  # Claude Code hook; reads the hook JSON on stdin.
  agent-awake = pkgs.writeShellApplication {
    name = "agent-awake";
    runtimeInputs = with pkgs; [
      coreutils
      jq
      systemd
    ];
    text = ''
      sid=$(jq -r '.session_id // "default"' | tr -cd 'A-Za-z0-9-')
      unit="agent-awake-''${sid:-default}"

      systemctl --user stop "$unit" 2>/dev/null || true
      if [ "''${1:-}" = start ]; then
        systemd-run --user --quiet --collect --unit="$unit" \
          systemd-inhibit --what=idle:sleep --who="Claude Code" --why="Agent working" sleep 3h
      fi
    '';
  };
in
lib.mkIf (config.desktop.enable && config.desktop.environment == "hyprland") {
  programs.hyprlock.enable = true;
  services.hypridle.enable = true;

  environment.systemPackages = [
    idlectl
    keepawake
    agent-awake
  ];

  environment.etc."hypr/hypridle.conf".text = inputs.home-manager.lib.hm.generators.toHyprconf {
    attrs = {
      general = {
        lock_cmd = idle "lock";
        before_sleep_cmd = "${loginctl} lock-session";
        after_sleep_cmd = idle "dpms-on";
        inhibit_sleep = 3;
      };
      listener = [
        {
          timeout = 570;
          on-timeout = idle "dim";
          on-resume = idle "undim";
        }
        {
          timeout = 600;
          on-timeout = "${loginctl} lock-session";
        }
        {
          timeout = 60;
          on-timeout = idle "dpms-off";
          on-resume = idle "dpms-on";
        }
        {
          timeout = 630;
          on-timeout = idle "dpms-off";
          on-resume = idle "dpms-on";
        }
        {
          timeout = 1800;
          on-timeout = idle "suspend";
        }
      ];
    };
  };

  systemd.user.services.hypridle = {
    serviceConfig.ExecStart = [
      ""
      "${lib.getExe config.services.hypridle.package} -c /etc/hypr/hypridle.conf"
    ];
  };

  systemd.user.services.wayland-pipewire-idle-inhibit = {
    description = "Inhibit idle while audio is playing";
    wantedBy = [ "graphical-session.target" ];
    after = [
      "graphical-session.target"
      "hypridle.service"
    ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${lib.getExe pkgs.wayland-pipewire-idle-inhibit} --idle-inhibitor d-bus --media-minimum-duration 10 --quiet";
      Restart = "on-failure";
      RestartSec = "5";
    };
  };
}
