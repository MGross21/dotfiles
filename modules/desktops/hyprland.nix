{ pkgs, lib, ... }:
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
    extraPortals = lib.mkForce (with pkgs; [
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ]);
  };
  programs.xwayland.enable = true;

  services.displayManager.ly.enable = true;

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