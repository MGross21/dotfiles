{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  hyprglass-plugin = pkgs.hyprlandPlugins.mkHyprlandPlugin {
    pluginName = "hyprglass";
    version = "0.7.0";
    src = inputs.hyprglass;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib
      cp hyprglass.so $out/lib/libhyprglass.so
      runHook postInstall
    '';

    meta = {
      description = "Liquid-glass blur, refraction and specular for windows and layer surfaces";
      homepage = "https://github.com/hyprnux/hyprglass";
      license = lib.licenses.bsd3;
      platforms = lib.platforms.linux;
    };
  };

  # Expects the setcap gpu-screen-recorder wrapper from programs.gpu-screen-recorder on PATH.
  record-toggle = pkgs.writeShellApplication {
    name = "record-toggle";
    runtimeInputs = with pkgs; [
      config.programs.hyprland.package
      coreutils
      jq
      slurp
    ];
    text = ''
      state="''${XDG_RUNTIME_DIR:-/tmp}/record-toggle"

      if [ -f "$state.pid" ] && kill -INT "$(cat "$state.pid")" 2>/dev/null; then
        hyprctl notify 5 3000 0 "Saved $(cat "$state.out")" >/dev/null
        exit 0
      fi

      case "''${1:-screen}" in
        screen) target=(-w screen) ;;
        window) target=(-w portal) ;;
        region)
          workspaces=$(hyprctl -j monitors | jq '[.[].activeWorkspace.id]')
          geom=$(hyprctl -j clients |
            jq -r --argjson ws "$workspaces" \
              '.[] | select(.mapped and (.hidden | not)) | select(.workspace.id as $w | $ws | any(. == $w))
                | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' |
            slurp -f '%wx%h+%x+%y') || exit 0
          target=(-w region -region "$geom")
          ;;
        *)
          echo "usage: record-toggle [screen|window|region]" >&2
          exit 1
          ;;
      esac

      mkdir -p ~/Videos
      out=~/Videos/"$(date +%Y%m%d_%H%M%S)".mp4
      echo "$out" >"$state.out"

      gpu-screen-recorder "''${target[@]}" -f 60 -a default_output -o "$out" &
      echo $! >"$state.pid"
      status=0
      wait $! || status=$?
      rm -f "$state.pid"
      if [ "$status" -ne 0 ]; then
        hyprctl notify 3 4000 0 "Recording failed (exit $status)" >/dev/null
      fi
    '';
  };
in
lib.mkIf (config.desktop.enable && config.desktop.environment == "hyprland") {
  environment.etc."hypr/plugins.lua".text = ''
    hl.plugin.load("${hyprglass-plugin}/lib/libhyprglass.so")
  '';

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  programs.gpu-screen-recorder.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = [
      "hyprland"
      "gtk"
    ];
  };

  services.displayManager.ly.enable = true;
  services.displayManager.ly.settings = {
    animation = "colormix";
    animation_timeout_sec = 0;
    auth_fails = 10;
    bigclock = "en";
    bigclock_12hr = true;
    brightness_down_cmd = "${pkgs.brightnessctl}/bin/brightnessctl -q -n s 10%-";
    brightness_down_key = "F5";
    brightness_up_cmd = "${pkgs.brightnessctl}/bin/brightnessctl -q -n s +10%";
    brightness_up_key = "F6";
    clear_password = true;
    cmatrix_min_codepoint = "0x21";
    cmatrix_max_codepoint = "0x7B";
    doom_fire_height = 6;
    doom_fire_spread = 2;
    full_color = true;
    gameoflife_entropy_interval = 10;
    gameoflife_frame_delay = 6;
    gameoflife_initial_density = 0.4;
    input_len = 34;
    path = "/run/current-system/sw/bin";
    restart_cmd = "/run/current-system/systemd/bin/systemctl reboot";
    save = true;
    shutdown_cmd = "/run/current-system/systemd/bin/systemctl poweroff";
    text_in_center = true;
    waylandsessions = "${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
    xsessions = "${config.services.displayManager.sessionData.desktops}/share/xsessions";
  };

  location.provider = "geoclue2";

  services.geoclue2.appConfig.gammastep = {
    isAllowed = true;
    isSystem = true;
  };

  environment.systemPackages = lib.mkOrder 200 (
    with pkgs;
    [
      hyprlock
      hypridle
      hyprpaper
      hyprpicker
      gammastep
      hyprshot

      ly

      quickshell
      wofi
      brightnessctl
      playerctl
      gpu-screen-recorder-gtk
      record-toggle
      nwg-displays
      uwsm
      xsettingsd

      nwg-look
      gnome-themes-extra
      adwaita-icon-theme
      materia-theme
      (tela-circle-icon-theme.overrideAttrs { dontCheckForBrokenSymlinks = true; })

      apple-cursor
    ]
  );

  systemd.user.services.quickshell = {
    description = "Quickshell bar";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    path = with pkgs; [
      bash
      coreutils
      gawk
      gnused
      systemd
      networkmanager
      ghostty
      hyprlock
    ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.quickshell}/bin/qs -c bar";
      Restart = "on-failure";
      RestartSec = "3";
    };
  };

  systemd.user.services.hyprpaper = {
    description = "Hyprpaper wallpaper daemon";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    environment.__EGL_VENDOR_LIBRARY_FILENAMES = "${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json";
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.hyprpaper}/bin/hyprpaper -c /etc/hypr/hyprpaper.conf";
      Restart = "on-failure";
    };
  };

  systemd.user.paths.hyprpaper-theme = {
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    pathConfig.PathChanged = "/etc/hypr/hyprpaper.conf";
  };

  systemd.user.services.hyprpaper-theme = {
    description = "Restart hyprpaper on theme change";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl --user restart hyprpaper.service";
    };
  };

  systemd.user.services.gammastep = {
    description = "Night light (geoclue2-located sunset/sunrise)";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.gammastep}/bin/gammastep -m wayland -l geoclue2 -t 6500:3000";
      Restart = "always";
      RestartSec = "10";
    };
  };

  systemd.user.services.xsettingsd = {
    description = "XSettings daemon for GTK theme consistency";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    unitConfig.ConditionEnvironment = "DISPLAY";
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.xsettingsd}/bin/xsettingsd -c /etc/xsettingsd/xsettingsd.conf";
      Restart = "on-failure";
      RestartSec = "3";
    };
  };
}
