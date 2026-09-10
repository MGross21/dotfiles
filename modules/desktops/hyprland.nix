{
  config,
  pkgs,
  lib,
  hyprglass,
  ...
}:
let
  # Built against the exact `pkgs.hyprland` the session runs, so the plugin ABI
  # matches by construction -- this is what hyprpm does by hand elsewhere.
  hyprglass-plugin = pkgs.hyprlandPlugins.mkHyprlandPlugin {
    pluginName = "hyprglass";
    version = "0.7.0";
    src = hyprglass;

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
in
lib.mkIf (config.desktop.environment == "hyprland") {
  # There is no `programs.hyprland.plugins` in the NixOS module (that option is
  # home-manager only), so the plugin is loaded from the Lua config instead.
  # Nix owns this file because only Nix knows the store path.
  environment.etc."hypr/plugins.lua".text = ''
    hl.plugin.load("${hyprglass-plugin}/lib/libhyprglass.so")
  '';

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

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
    input_len = 24;
    path = "/run/current-system/sw/bin";
    restart_cmd = "/run/current-system/systemd/bin/systemctl reboot";
    save = true;
    shutdown_cmd = "/run/current-system/systemd/bin/systemctl poweroff";
    text_in_center = true;
    waylandsessions = "${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
    xsessions = "${config.services.displayManager.sessionData.desktops}/share/xsessions";
  };

  # Night light. geoclue2 resolves the location from wifi/NMEA so the sunset
  # and sunrise times follow the actual date and place instead of a fixed
  # clock -- which is the one thing hyprsunset's profiles cannot do.
  location.provider = "geoclue2";

  # isSystem skips the agent prompt: gammastep runs headless from systemd and
  # has no way to answer one.
  services.geoclue2.appConfig.gammastep = {
    isAllowed = true;
    isSystem = true;
  };

  # Wayland required packages
  environment.systemPackages = with pkgs; [
    hyprlock
    hypridle
    hyprpaper
    hyprpicker
    gammastep
    hyprshot
    # hyprcursor # I dont like this

    ly

    quickshell
    wofi
    brightnessctl
    playerctl
    kooha
    nwg-displays
    uwsm
    xsettingsd

    # THEMING
    nwg-look
    gnome-themes-extra
    adwaita-icon-theme # symbolic icons for the bar
    materia-theme
    tela-circle-icon-theme

    apple-cursor
  ];

  # For NVIDIA + Hyprland, you may need:
  # environment.variables.LIBVA_DRIVER_NAME = "nvidia";
  # environment.variables.LIBVA_DRIVERS_PATH = "${pkgs.libva}/lib/${ /* arch */ }";

  systemd.user.services.quickshell = {
    description = "Quickshell bar";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    # Commands the bar's modules spawn.
    path = with pkgs; [
      bash
      coreutils
      gawk
      gnused
      systemd
      networkmanager # nmcli backs the network widget
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
    # glvnd probes every ICD in egl_vendor.d, so the nvidia one opens /dev/nvidia0
    # just to answer the capability query. hyprpaper only needs the mesa ICD.
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
      # 6500K is neutral, so daytime is a no-op and only the night leg tints.
      ExecStart = "${pkgs.gammastep}/bin/gammastep -m wayland -l geoclue2 -t 6500:3000";
      # A cold boot can beat geoclue to a fix; gammastep exits rather than wait.
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
