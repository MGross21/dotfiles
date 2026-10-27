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
  environment.etc."hypr/xdph.conf".text = inputs.home-manager.lib.hm.generators.toHyprconf {
    attrs.screencopy.max_fps = 60;
  };

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
    brightness_down_cmd = "${lib.getExe pkgs.brightnessctl} -q -n s 10%-";
    brightness_down_key = "F5";
    brightness_up_cmd = "${lib.getExe pkgs.brightnessctl} -q -n s +10%";
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

  home-manager.sharedModules = [
    {
      services.gammastep = {
        enable = true;
        provider = "geoclue2";
        temperature = {
          day = 6500;
          night = 3000;
        };
        settings.general.adjustment-method = "wayland";
      };
      services.hyprpolkitagent.enable = true;
      services.dunst = {
        enable = true;
        settings =
          let
            c = config.theming.colors;
          in
          {
            global = {
              monitor = 0;
              width = 280;
              height = "(0, 80)";
              origin = "top-right";
              offset = "(15, 15)";
              indicate_hidden = true;
              shrink = true;
              transparency = 0;
              separator_height = 0;
              padding = 14;
              horizontal_padding = 18;
              frame_width = 1;
              frame_color = c.black;
              separator_color = c.bg;
              sort = true;
              idle_threshold = 120;
              font = "${config.theming.fonts.monospace.name} 9";
              line_height = 0;
              markup = "full";
              format = "<b>%s</b>\\n%b";
              alignment = "left";
              vertical_alignment = "top";
              show_age_threshold = 60;
              word_wrap = true;
              ellipsize = "end";
              ignore_newline = false;
              stack_duplicates = true;
              hide_duplicate_count = false;
              show_indicators = true;
              icon_position = "left";
              min_icon_size = 16;
              max_icon_size = 32;
              sticky_history = true;
              history_length = 100;
              title = "Dunst";
              class = "Dunst";
              corner_radius = 12;
              always_run_script = true;
              mouse_left_click = "close_current";
              mouse_middle_click = "do_action";
              mouse_right_click = "close_all";
              close = "ctrl+shift+space";
              close_all = "ctrl+shift+BackSpace";
              history = "ctrl+shift+period";
              context = "ctrl+shift+comma";
            };
            urgency_low = {
              background = c.bg;
              foreground = c.fg;
              frame_color = c.black;
              timeout = 3;
            };
            urgency_normal = {
              background = c.black;
              foreground = c.fg;
              frame_color = c.brightBlack;
              timeout = 5;
            };
            urgency_critical = {
              background = c.black;
              foreground = c.fg;
              frame_color = c.red;
              timeout = 0;
            };
          };
      };
    }
  ];

  services.geoclue2.appConfig.gammastep = {
    isAllowed = true;
    isSystem = true;
  };

  # Ahead of papirus so tela/gnome-themes win the shared icon dirs in system-path.
  environment.systemPackages = lib.mkOrder 200 (
    with pkgs;
    [
      hyprpaper
      hyprpicker
      hyprshot

      ly

      quickshell
      qt6.qtmultimedia
      brightnessctl
      playerctl
      gpu-screen-recorder-gtk
      record-toggle
      uwsm

      nwg-look
      gnome-themes-extra
      adwaita-icon-theme
      materia-theme
      tela-circle-icon-theme
    ]
  );

  systemd.user.services.quickshell = {
    description = "Quickshell bar";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    # uwsm resolves launched entries' executables against this PATH.
    path =
      with pkgs;
      [
        bash
        coreutils
        gawk
        gnused
        systemd
        networkmanager
        qrencode
        zbar
        ghostty
        uwsm
        "/run/wrappers"
        "/run/current-system/sw"
      ]
      ++ map (user: "/etc/profiles/per-user/${user}") (lib.attrNames config.home-manager.users);
    serviceConfig = {
      Type = "simple";
      ExecStart = "${lib.getExe' pkgs.quickshell "qs"} -c bar";
      Restart = "on-failure";
      RestartSec = "3";
    };
  };

  systemd.user.services.hyprpaper = {
    description = "Hyprpaper wallpaper daemon";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${lib.getExe pkgs.hyprpaper} -c /etc/hypr/hyprpaper.conf";
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
      ExecStart = "${lib.getExe' pkgs.systemd "systemctl"} --user restart hyprpaper.service";
    };
  };

}
