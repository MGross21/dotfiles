{ pkgs, lib, ... }:

{
  # HYPRLAND
  programs.hyprland = {
    enable = true;
    package = pkgs.hyprland;
  };

  # XDG Desktop Portal for sandboxed applications
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
  };

  # Wayland required packages
  environment.systemPackages = with pkgs; [
    hyprland
    hyprlock
    hypridle
    hyprpaper
    hyprpicker
    hyprsunset
    hyprcursor
    
    waybar
    wofi
    brightnessctl
    playerctl
    kooha
    nwg-displays
    uwsm
    network-manager-applet
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
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
      ExecStart = "${pkgs.gnome-polkit}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };
}