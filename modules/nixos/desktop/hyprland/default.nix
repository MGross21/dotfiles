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
    version = "1.1.0";
    src = inputs.hyprglass;

    nativeBuildInputs = [ pkgs.wayland-scanner ];
    makeFlags = [ "HYPRGLASS_VERSION=${hyprglass-plugin.version}" ];

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
    text = builtins.readFile ./record-toggle.sh;
  };
in
lib.mkIf (config.desktop.enable && config.desktop.environment == "hyprland") {
  environment.etc."hypr/xdph.conf".text = inputs.home-manager.lib.hm.generators.toHyprconf {
    attrs.screencopy.max_fps = 60;
  };

  environment.etc."hypr/plugins.lua".text = ''
    hl.plugin.load("${hyprglass-plugin}/lib/libhyprglass.so")
  '';

  environment.etc."hypr/workspaces.lua".text =
    lib.optionalString (config.desktop.primaryMonitor != "")
      ''
        hl.workspace_rule(${
          lib.generators.toLua { } {
            workspace = "1";
            monitor = config.desktop.primaryMonitor;
            default = true;
          }
        })
      '';

  programs.hyprland = {
    enable = true;
    withUWSM = true;
  };

  programs.gpu-screen-recorder.enable = true;

  xdg.portal = {
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
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

      brightnessctl
      playerctl
      gpu-screen-recorder-gtk
      record-toggle

      nwg-look
      gnome-themes-extra
      adwaita-icon-theme
      materia-theme
      tela-circle-icon-theme
    ]
  );

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
