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
    package = pkgs.hyprland;
    withUWSM = true;
    xwayland.enable = true;
  };

  # XDG Desktop Portal for sandboxed applications
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
    ];
    config.common.default = [
      "hyprland"
    ];
  };

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
    bigclock = "en";
    bigclock_12hr = true;
    bigclock_seconds = false;
    blank_box = true;
    box_title = "null";
    brightness_down_cmd = "/usr/bin/brightnessctl -q -n s 10%-";
    brightness_down_key = "F5";
    brightness_up_cmd = "/usr/bin/brightnessctl -q -n s +10%";
    brightness_up_key = "F6";
    clear_password = true;
    clock = "null";
    cmatrix_min_codepoint = "0x21";
    cmatrix_max_codepoint = "0x7B";
    custom_sessions = "/etc/ly/custom-sessions";
    default_input = "login";
    doom_fire_height = 6;
    doom_fire_spread = 2;
    dur_file_path = "/etc/ly/example.dur";
    dur_x_offset = 0;
    dur_y_offset = 0;
    edge_margin = 0;
    full_color = true;
    gameoflife_entropy_interval = 10;
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
  environment.systemPackages = with pkgs; [
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

    apple-cursor
  ];

  # For NVIDIA + Hyprland, you may need:
  # environment.variables.LIBVA_DRIVER_NAME = "nvidia";
  # environment.variables.LIBVA_DRIVERS_PATH = "${pkgs.libva}/lib/${ /* arch */ }";

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
