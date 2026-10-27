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
  };

  config = lib.mkIf cfg.enable {
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      jack.enable = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };

    services.udisks2.enable = true;
    services.gvfs.enable = true;
    services.printing.enable = true;

    security.pam.services.ly.enableGnomeKeyring = true;

    environment.sessionVariables = {
      MOZ_DBUS_REMOTE = "1";
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_GTK_TITLEBAR_DECORATION = "client";
      MOZ_DISABLE_SPLASH = "1";
    };

    programs.firefox.enable = true;

    environment.systemPackages = with pkgs; [

      papirus-folders

      libxres
      gamemode
      xwayland
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
