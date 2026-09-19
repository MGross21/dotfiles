{
  config,
  pkgs,
  lib,
  ...
}:
lib.mkIf (config.desktop.enable && config.desktop.environment == "gnome") {
  programs.xwayland.enable = true;

  services = {
    desktopManager.gnome.enable = true;
    displayManager.gdm.enable = true;
    gnome.core-apps.enable = false;
    gnome.games.enable = false;
    gnome.core-developer-tools.enable = false;
    gnome.localsearch.enable = false;
    gnome.tinysparql.enable = false;
  };

  environment.gnome.excludePackages = with pkgs; [
    gnome-tour
    nixos-render-docs
  ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
    QT_QPA_PLATFORM = "wayland";
  };

  environment.systemPackages = with pkgs; [
    gnomeExtensions.dash-to-dock
    gnomeExtensions.blur-my-shell
    gnomeExtensions.user-themes
    mactahoe-gtk-theme
    mactahoe-icon-theme
    mactahoe-cursor-theme
  ];

  programs.dconf.enable = true;
  programs.dconf.profiles = {
    user.databases = [
      {
        settings = {
          "org/gnome/desktop/interface" = {
            color-scheme = "prefer-dark";
            accent-color = "red";
            show-battery-percentage = true;
            gtk-theme = "MacTahoe-Dark";
            icon-theme = "MacTahoe";
            cursor-theme = "MacTahoe-cursors";
          };
          "org/gnome/desktop/background" = {
            picture-uri = "file://${config.stylix.image}";
            picture-uri-dark = "file://${config.stylix.image}";
          };
          "org/gnome/desktop/screensaver" = {
            picture-uri = "file://${config.stylix.image}";
            picture-uri-dark = "file://${config.stylix.image}";
          };
          "org/gnome/desktop/session" = with lib.gvariant; {
            idle-delay = mkUint32 0;
          };
          "org/gtk/settings/file-chooser" = {
            clock-format = "12h";
          };
          "org/gnome/settings-daemon/plugins/housekeeping" = with lib.gvariant; {
            donation-reminder-last-shown = mkInt64 9223372036854775807;
          };
          "org/gnome/settings-daemon/plugins/power" = with lib.gvariant; {
            ambient-enabled = false;
            idle-dim = false;
            power-button-action = "nothing";
            sleep-inactive-ac-type = "nothing";
            sleep-inactive-ac-timeout = mkUint32 0;
            sleep-inactive-battery-type = "nothing";
            sleep-inactive-battery-timeout = mkUint32 0;
          };
          "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = with lib.gvariant; {
            blur = true;
            brightness = mkDouble 0.6;
            sigma = mkInt32 30;
            static-blur = true;
            style-dash-to-dock = mkInt32 0;
          };
          "org/gnome/shell/extensions/blur-my-shell/appfolder" = with lib.gvariant; {
            brightness = mkDouble 0.6;
            sigma = mkInt32 30;
          };
          "org/gnome/shell/extensions/blur-my-shell/panel" = with lib.gvariant; {
            brightness = mkDouble 0.6;
            sigma = mkInt32 30;
          };
          "org/gnome/shell/extensions/blur-my-shell/window-list" = with lib.gvariant; {
            brightness = mkDouble 0.6;
            sigma = mkInt32 30;
          };
          "org/gnome/shell/extensions/blur-my-shell" = with lib.gvariant; {
            settings-version = mkInt32 2;
          };
          "org/gnome/shell" = {
            enabled-extensions = [
              "dash-to-dock@micxgx.gmail.com"
              "blur-my-shell@aunetx"
              "user-theme@gnome-shell-extensions.gcampax.github.com"
            ];
          };
        };
      }
    ];
  };
}
