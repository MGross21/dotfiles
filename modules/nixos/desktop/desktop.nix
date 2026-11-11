{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.desktop;
in
{
  options.desktop = {
    enable = lib.mkEnableOption "the graphical desktop stack";

    environment = lib.mkOption {
      type = lib.types.enum [
        "hyprland"
        "gnome"
      ];
      default = "hyprland";
      description = "Active desktop environment.";
    };

    primaryMonitor = lib.mkOption {
      type = lib.types.str;
      default = ""; # unpinned
      description = "Output for workspace 1 and lock screen widgets.";
    };
  };

  config = lib.mkIf cfg.enable {
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    services.udisks2.enable = true;
    services.gvfs.enable = true;
    services.printing.enable = true;

    security.pam.services.ly.enableGnomeKeyring = true;

    environment.systemPackages = with pkgs; [
      papirus-folders

      libxres
      gamemode
      qt5.qtbase
      qt5.qtwayland
      qt6.qtbase
      qt6.qtwayland

      pavucontrol

      libsecret
      seahorse
    ];

    fonts.enableDefaultPackages = false;
    fonts.packages = with pkgs; [
      ubuntu-classic
      nerd-fonts.symbols-only
      noto-fonts
      noto-fonts-cjk-sans
      dejavu_fonts
      liberation_ttf
      gyre-fonts
      carlito
      caladea
    ];
  };
}
