{ pkgs, lib, ... }:
let
  macTahoeDay = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/vinceliuice/MacTahoe-gtk-theme/refs/heads/main/wallpaper/MacTahoe-day.jpeg";
    hash = "sha256-2WkJEdId97WUpfIAh0qHhfrDEZ1pHi4//9UqlROIeOI=";
  };
  macTahoeNight = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/vinceliuice/MacTahoe-gtk-theme/refs/heads/main/wallpaper/MacTahoe-night.jpeg";
    hash = "sha256-2OT/lQEYiquKT6n5UVvtgl63OrH7ZazKMKnitwjMKWU=";
  };

  quietInkscape = pkgs.writeShellScriptBin "inkscape" ''
    exec ${pkgs.inkscape}/bin/inkscape "$@" 2>/dev/null
  '';

  macTahoeGtkTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "MacTahoe-gtk-theme";
    version = "unstable-2024";
    src = pkgs.fetchFromGitHub {
      owner = "vinceliuice";
      repo = "MacTahoe-gtk-theme";
      rev = "main";
      hash = "sha256-xS/RAPAREzteA6BRL3ZGrKk8Uml6/AjZRGQGQCOCrek=";
    };

    nativeBuildInputs = with pkgs; [
      bash
      sudo
      which
      coreutils
      util-linux
      procps
      file
      findutils
      gnugrep
      gnused
      gawk
      shadow
      glibc.bin
      sassc
      glib
      libxml2
      optipng
      inkscape
    ];

    postPatch = ''
      substituteInPlace libs/lib-core.sh \
        --replace-fail 'MY_HOME=$(getent passwd "''${MY_USERNAME}" | cut -d: -f6)' 'MY_HOME="''${HOME}"'
    '';

    dontConfigure = true;
    buildPhase = ''
      runHook preBuild
      export HOME="$TMPDIR/home"
      export XDG_CACHE_HOME="$TMPDIR/cache"
      export XDG_CONFIG_HOME="$TMPDIR/config"
      export PATH="${pkgs.glibc.bin}/bin:${pkgs.shadow}/bin:$PATH"
      export PATH="${quietInkscape}/bin:$PATH"
      mkdir -p "$HOME"
      mkdir -p "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME"
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      export PATH="${quietInkscape}/bin:$PATH"
      mkdir -p "$out/share/themes"
      unset name
      bash ./install.sh -d "$out/share/themes" -n MacTahoe -t default -c dark
      test -n "$(find "$out/share/themes" -maxdepth 1 -type d -name 'MacTahoe*' | head -n 1)"
      runHook postInstall
    '';
  };

  macTahoeIconTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "MacTahoe-icon-theme";
    version = "unstable-2024";
    src = pkgs.fetchFromGitHub {
      owner = "vinceliuice";
      repo = "MacTahoe-icon-theme";
      rev = "main";
      hash = "sha256-a21zLinYTG6fpdQhKcn/3GzVUKd0bQOnY74609C5I7k=";
    };

    nativeBuildInputs = with pkgs; [
      bash
      coreutils
      findutils
      gnugrep
      gnused
      gtk3
    ];

    dontConfigure = true;
    buildPhase = ''
      runHook preBuild
      export HOME="$TMPDIR/home"
      export PATH="${quietInkscape}/bin:$PATH"
      mkdir -p "$HOME"
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      export PATH="${quietInkscape}/bin:$PATH"
      mkdir -p "$out/share/icons"
      unset name
      bash ./install.sh -d "$out/share/icons" -n MacTahoe -t default
      test -n "$(find "$out/share/icons" -maxdepth 1 -type d -name 'MacTahoe*' | head -n 1)"
      runHook postInstall
    '';
  };

  macTahoeCursorTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "MacTahoe-cursor-theme";
    version = "unstable-2024";
    src = pkgs.fetchFromGitHub {
      owner = "vinceliuice";
      repo = "MacTahoe-icon-theme";
      rev = "main";
      hash = "sha256-a21zLinYTG6fpdQhKcn/3GzVUKd0bQOnY74609C5I7k=";
    };

    nativeBuildInputs = with pkgs; [
      bash
      which
      findutils
      xcursorgen
      inkscape
      fontconfig
    ];

    dontConfigure = true;
    buildPhase = ''
      runHook preBuild
      export HOME="$TMPDIR/home"
      export XDG_CACHE_HOME="$TMPDIR/cache"
      export XDG_CONFIG_HOME="$TMPDIR/config"
      export FONTCONFIG_FILE="${pkgs.fontconfig.out}/etc/fonts/fonts.conf"
      export PATH="${quietInkscape}/bin:$PATH"
      mkdir -p "$HOME" "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME"
      cd cursors
      bash ./build.sh
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p "$out/share/icons/MacTahoe-cursors"
      mkdir -p "$out/share/icons/MacTahoe-dark-cursors"

      if [ -d cursors ]; then
        cursorBase="cursors"
      else
        cursorBase="."
      fi

      lightDist="$(find "$cursorBase" -maxdepth 1 -type d -name 'dist*' ! -name 'dist-dark*' | head -n 1)"
      darkDist="$(find "$cursorBase" -maxdepth 1 -type d -name 'dist-dark*' | head -n 1)"

      test -n "$lightDist"
      test -n "$darkDist"

      cp -r "$lightDist"/. "$out/share/icons/MacTahoe-cursors/"
      cp -r "$darkDist"/. "$out/share/icons/MacTahoe-dark-cursors/"
      runHook postInstall
    '';
  };
in
{
  programs.xwayland.enable = true;

  services = {
    desktopManager.gnome.enable = true;
    displayManager.gdm.enable = true;
    displayManager.gdm.wayland = true;
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
    macTahoeGtkTheme
    macTahoeIconTheme
    macTahoeCursorTheme
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
            picture-uri = "file://${macTahoeDay}";
            picture-uri-dark = "file://${macTahoeNight}";
          };
          "org/gnome/desktop/screensaver" = {
            picture-uri = "file://${macTahoeDay}";
            picture-uri-dark = "file://${macTahoeNight}";
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
