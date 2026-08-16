{
  config,
  pkgs,
  lib,
  mactahoe-gtk,
  mactahoe-icons,
  ...
}:
let
  # cursor build.sh rasterizes SVGs with `inkscape -o out.png -w W -h H in.svg`.
  # Shim it to rsvg-convert (tiny, cached) so we skip building inkscape from source.
  inkscapeShim = pkgs.writeShellScriptBin "inkscape" ''
    out= w= h= svg=
    while [ $# -gt 0 ]; do
      case "$1" in
        -o) out="$2"; shift 2 ;;
        -w) w="$2"; shift 2 ;;
        -h) h="$2"; shift 2 ;;
        *.svg) svg="$1"; shift ;;
        *) shift ;;
      esac
    done
    [ -n "$h" ] || h="$w"
    exec ${pkgs.librsvg}/bin/rsvg-convert -w "$w" -h "$h" -o "$out" "$svg"
  '';

  macTahoeGtkTheme = pkgs.stdenvNoCC.mkDerivation {
    pname = "MacTahoe-gtk-theme";
    version = "unstable-2024";
    src = mactahoe-gtk;

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
      mkdir -p "$HOME"
      mkdir -p "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME"
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
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
    src = mactahoe-icons;

    # upstream ships a dangling symbolic-icon alias (globe->network-workgroup)
    dontCheckForBrokenSymlinks = true;

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
      mkdir -p "$HOME"
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
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
    src = mactahoe-icons;

    nativeBuildInputs = with pkgs; [
      bash
      which
      findutils
      xcursorgen
      inkscapeShim # rsvg-backed inkscape stand-in
    ];

    dontConfigure = true;
    buildPhase = ''
      runHook preBuild
      export HOME="$TMPDIR/home"
      export XDG_CACHE_HOME="$TMPDIR/cache"
      export XDG_CONFIG_HOME="$TMPDIR/config"
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
lib.mkIf (config.desktop.environment == "gnome") {
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
          # wallpaper follows active theme, same source as hyprland (stylix.image)
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
