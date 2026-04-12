{
  config,
  pkgs,
  lib,
  ...
}:
let
  unstable = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") {
    config.allowUnfree = true;
  };
in
{
  # HYPRLAND
  programs.hyprland = {
    enable = true;
    package = unstable.hyprland;
  };

  # XDG Desktop Portal for sandboxed applications
  xdg.portal = {
    enable = true;
    extraPortals = lib.mkForce (
      with pkgs;
      [
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-gtk
      ]
    );
  };
  programs.xwayland.enable = true;

  services.displayManager.ly.enable = true;
  services.displayManager.ly.settings = {
    allow_empty_password = false;
    animation = "colormix";
    animation_timeout_sec = 0;
    asterisk = "*";
    auth_fails = 10;
    battery_id = "BAT1";
    auto_login_service = "ly-autologin";
    auto_login_session = "null";
    auto_login_user = "null";
    bg = "0x00151515";
    bigclock = "en";
    bigclock_12hr = true;
    bigclock_seconds = false;
    blank_box = true;
    border_fg = "0x00FC595F";
    box_title = "null";
    brightness_down_cmd = "/usr/bin/brightnessctl -q -n s 10%-";
    brightness_down_key = "F5";
    brightness_up_cmd = "/usr/bin/brightnessctl -q -n s +10%";
    brightness_up_key = "F6";
    clear_password = true;
    clock = "null";
    cmatrix_fg = "0x00A63C40";
    cmatrix_head_col = "0x01FFFFFF";
    cmatrix_min_codepoint = "0x21";
    cmatrix_max_codepoint = "0x7B";
    colormix_col1 = "0x004A1E20";
    colormix_col2 = "0x008C2F33";
    colormix_col3 = "0x00B44B4F";
    custom_sessions = "/etc/ly/custom-sessions";
    default_input = "login";
    doom_fire_height = 6;
    doom_fire_spread = 2;
    doom_top_color = "0x00832E31";
    doom_middle_color = "0x00D3494E";
    doom_bottom_color = "0x00FC595F";
    dur_file_path = "/etc/ly/example.dur";
    dur_x_offset = 0;
    dur_y_offset = 0;
    edge_margin = 0;
    error_bg = "0x00151515";
    error_fg = "0x01832E31";
    fg = "0x00A1B0B8";
    full_color = true;
    gameoflife_entropy_interval = 10;
    gameoflife_fg = "0x00A63C40";
    gameoflife_frame_delay = 6;
    gameoflife_initial_density = 0.4;
    hibernate_cmd = "null";
    hibernate_key = "F4";
    hide_borders = false;
    hide_key_hints = false;
    hide_keyboard_locks = false;
    hide_version_string = false;
    inactivity_cmd = "null";
    inactivity_delay = 0;
    initial_info_text = "null";
    input_len = 34;
    lang = "en";
    login_cmd = "null";
    login_defs_path = "/etc/login.defs";
    logout_cmd = "null";
    ly_log = "/var/log/ly.log";
    margin_box_h = 2;
    margin_box_v = 1;
    min_refresh_delta = 5;
    numlock = false;
    path = "/run/current-system/sw/bin";
    restart_cmd = "/run/current-system/systemd/bin/systemctl reboot";
    restart_key = "F2";
    save = true;
    service_name = "ly";
    session_log = ".local/state/ly-session.log";
    shutdown_cmd = "/run/current-system/systemd/bin/systemctl poweroff";
    shutdown_key = "F1";
    sleep_cmd = "null";
    sleep_key = "F3";
    start_cmd = "null";
    text_in_center = true;
    vi_default_mode = "normal";
    vi_mode = false;
    waylandsessions = "${config.services.displayManager.sessionData.desktops}/share/wayland-sessions";
    x_cmd = "/usr/bin/X";
    xauth_cmd = "/usr/bin/xauth";
    xinitrc = "null";
    xsessions = "${config.services.displayManager.sessionData.desktops}/share/xsessions";
  };

  # Wayland required packages
  environment.systemPackages = with unstable; [
    hyprland
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
    papirus-icon-theme

    apple-cursor
  ];

  # For NVIDIA + Hyprland, you may need:
  # environment.variables.LIBVA_DRIVER_NAME = "nvidia";
  # environment.variables.LIBVA_DRIVERS_PATH = "${pkgs.libva}/lib/${ /* arch */ }";

  # Polkit agent for authentication
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "GNOME PolicyKit authentication agent";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  systemd.user.services.xsettingsd = {
    description = "XSettings daemon for GTK theme consistency";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.xsettingsd}/bin/xsettingsd";
      Restart = "on-failure";
    };
  };
}
