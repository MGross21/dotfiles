{
  config,
  pkgs,
  lib,
  ...
}:
{
  # HYPRLAND
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  xdg.portal = {
    enable = true;
    config.common.default = [ "hyprland" ];
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
    path = "/run/current-system/sw/bin";
    restart_cmd = "/run/current-system/systemd/bin/systemctl reboot";
    save = true;
    shutdown_cmd = "/run/current-system/systemd/bin/systemctl poweroff";
    text_in_center = true;
    waylandsessions = "${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
    xsessions = "${config.services.displayManager.sessionData.desktops}/share/xsessions";
  };

  # Wayland required packages
  environment.systemPackages = with pkgs; [
    hyprlock
    hypridle
    hyprpaper
    hyprpicker
    hyprsunset
    hyprshot
    # hyprcursor # I dont like this

    ly

    waybar
    wofi
    brightnessctl
    playerctl
    kooha
    nwg-displays
    uwsm
    networkmanagerapplet
    xsettingsd

    # THEMING
    nwg-look
    gnome-themes-extra
    materia-theme
    tela-circle-icon-theme

    apple-cursor
  ];

  # For NVIDIA + Hyprland, you may need:
  # environment.variables.LIBVA_DRIVER_NAME = "nvidia";
  # environment.variables.LIBVA_DRIVERS_PATH = "${pkgs.libva}/lib/${ /* arch */ }";

  systemd.user.services.hyprpaper = {
    description = "Hyprpaper wallpaper daemon";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.hyprpaper}/bin/hyprpaper -c /etc/hypr/hyprpaper.conf";
      Restart = "on-failure";
      Slice = "session.slice";
    };
  };

  systemd.user.paths.hyprpaper-theme = {
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    pathConfig.PathChanged = "/etc/hypr/hyprpaper.conf";
  };

  systemd.user.services.hyprpaper-theme = {
    description = "Restart hyprpaper on theme change";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.systemd}/bin/systemctl --user restart hyprpaper.service";
    };
  };

  systemd.user.services.xsettingsd = {
    description = "XSettings daemon for GTK theme consistency";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.xsettingsd}/bin/xsettingsd -c /etc/xsettingsd/xsettingsd.conf";
      Restart = "on-failure";
    };
  };
}
