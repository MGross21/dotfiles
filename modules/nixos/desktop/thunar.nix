{
  config,
  lib,
  pkgs,
  ...
}:
let
  script =
    name: runtimeInputs: text:
    lib.getExe (pkgs.writeShellApplication { inherit name runtimeInputs text; });

  copyPath = script "thunar-copy-path" [ pkgs.wl-clipboard pkgs.libnotify ] ''
    wl-copy -- "$(printf '%s\n' "$@")"
    notify-send -a Thunar "Copied $# path(s)"
  '';

  setWallpaper = script "thunar-set-wallpaper" [ pkgs.libnotify ] ''
    hyprctl hyprpaper wallpaper ",$1"
    notify-send -a Thunar "Wallpaper set" "$(basename "$1")"
  '';

  checksum = script "thunar-checksum" [ pkgs.wl-clipboard pkgs.libnotify ] ''
    sums=$(cd "$(dirname "$1")" && sha256sum -- "''${@##*/}")
    wl-copy -- "$sums"
    notify-send -a Thunar "SHA-256 (copied)" "$sums"
  '';

  convert = script "thunar-image-convert" [ pkgs.imagemagick pkgs.libnotify ] ''
    ext=$1
    shift
    for f in "$@"; do
      magick "$f" "''${f%.*}.$ext"
    done
    notify-send -a Thunar "Converted $# image(s) to $ext"
  '';

  resize = script "thunar-image-resize" [ pkgs.imagemagick pkgs.libnotify ] ''
    for f in "$@"; do
      magick "$f" -resize 50% "''${f%.*}-half.''${f##*.}"
    done
    notify-send -a Thunar "Resized $# image(s) to 50%"
  '';

  optimize =
    script "thunar-image-optimize"
      [
        pkgs.oxipng
        pkgs.jpegoptim
        pkgs.libnotify
      ]
      ''
        for f in "$@"; do
          case "''${f,,}" in
            *.png) oxipng -q -o 4 --strip safe -- "$f" ;;
            *.jpg | *.jpeg) jpegoptim -q --strip-all -- "$f" ;;
          esac
        done
        notify-send -a Thunar "Optimized $# image(s)"
      '';

  actions = [
    {
      id = "terminal";
      name = "Open Terminal Here";
      icon = "utilities-terminal";
      command = "ghostty --working-directory=%f";
      dirs = true;
      accel = "<Primary><Alt>t";
    }
    {
      id = "yazi";
      name = "Open in Yazi";
      icon = "system-file-manager";
      command = "ghostty --working-directory=%f -e yazi";
      dirs = true;
      accel = "<Primary><Alt>y";
    }
    {
      id = "code";
      name = "Open in VS Code";
      icon = "vscode";
      command = "code %F";
      dirs = true;
      types = [
        "text-files"
        "other-files"
      ];
      accel = "<Primary><Alt>c";
    }
    {
      id = "nvim";
      name = "Edit in Neovim";
      icon = "nvim";
      command = "ghostty -e nvim %F";
      types = [ "text-files" ];
      accel = "<Primary><Alt>e";
    }
    {
      id = "copy-path";
      name = "Copy Path";
      icon = "edit-copy";
      command = "${copyPath} %F";
      dirs = true;
      types = [
        "audio-files"
        "image-files"
        "text-files"
        "video-files"
        "other-files"
      ];
      accel = "<Primary><Shift>c";
    }
    {
      id = "checksum";
      name = "SHA-256 Checksum";
      icon = "security-high";
      command = "${checksum} %F";
      types = [
        "audio-files"
        "image-files"
        "text-files"
        "video-files"
        "other-files"
      ];
    }
    {
      id = "wallpaper";
      name = "Set as Wallpaper";
      icon = "preferences-desktop-wallpaper";
      command = "${setWallpaper} %f";
      range = "1";
      types = [ "image-files" ];
      accel = "<Primary><Alt>w";
    }
    {
      id = "to-png";
      name = "Convert to PNG";
      submenu = "Image";
      icon = "image-x-generic";
      command = "${convert} png %F";
      types = [ "image-files" ];
    }
    {
      id = "to-jpg";
      name = "Convert to JPEG";
      submenu = "Image";
      icon = "image-x-generic";
      command = "${convert} jpg %F";
      types = [ "image-files" ];
    }
    {
      id = "to-webp";
      name = "Convert to WebP";
      submenu = "Image";
      icon = "image-x-generic";
      command = "${convert} webp %F";
      types = [ "image-files" ];
    }
    {
      id = "resize";
      name = "Resize to 50%";
      submenu = "Image";
      icon = "transform-scale";
      command = "${resize} %F";
      types = [ "image-files" ];
    }
    {
      id = "optimize";
      name = "Optimize (lossless)";
      submenu = "Image";
      icon = "image-x-generic";
      command = "${optimize} %F";
      patterns = "*.png;*.jpg;*.jpeg;*.PNG;*.JPG;*.JPEG";
      types = [ "image-files" ];
    }
  ];

  ucaXml = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <actions>
    ${lib.concatMapStrings (a: ''
      <action>
        <icon>${a.icon}</icon>
        <name>${a.name}</name>
        <submenu>${a.submenu or ""}</submenu>
        <unique-id>${a.id}</unique-id>
        <command>${a.command}</command>
        <description>${a.name}</description>
        <range>${a.range or "*"}</range>
        <patterns>${a.patterns or "*"}</patterns>
        ${lib.optionalString (a.dirs or false) "<directories/>"}
        ${lib.concatMapStrings (t: "<${t}/>") (a.types or [ ])}
      </action>
    '') actions}
    </actions>
  '';

  accels = lib.concatMapStrings (a: ''
    (gtk_accel_path "<Actions>/ThunarActions/uca-action-${a.id}" "${a.accel}")
  '') (lib.filter (a: a ? accel) actions);
in
lib.mkIf config.desktop.enable {
  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-volman
      thunar-archive-plugin
      thunar-media-tags-plugin
      thunar-vcs-plugin
      thunar-shares-plugin
    ];
  };

  # Backend for thunar-archive-plugin.
  environment.systemPackages = [ pkgs.file-roller ];

  services.tumbler.enable = true;
  programs.gdk-pixbuf.modulePackages = with pkgs; [
    webp-pixbuf-loader
    libavif
    libheif.lib
    libjxl
  ];

  # Terminal for Terminal=true desktop entries.
  xdg.terminal-exec = {
    enable = true;
    settings.default = [ "com.mitchellh.ghostty.desktop" ];
  };

  home-manager.sharedModules = [
    {
      xfconf.settings.thunar = {
        last-show-hidden = true;
        last-image-preview-visible = true;
        misc-image-preview-mode = "THUNAR_IMAGE_PREVIEW_MODE_STANDALONE";
        misc-thumbnail-mode = "THUNAR_THUMBNAIL_MODE_ALWAYS";
        misc-folders-first = true;
        misc-single-click = false;
        misc-middle-click-in-tab = true;
        misc-full-path-in-tab-title = true;
        misc-date-style = "THUNAR_DATE_STYLE_YYYYMMDD";
        misc-confirm-close-multiple-tabs = true;
      };

      # Thunar replaces these symlinks on save; force reclaims them.
      xdg.configFile = {
        "Thunar/uca.xml" = {
          text = ucaXml;
          force = true;
        };
        "Thunar/accels.scm" = {
          text = accels;
          force = true;
        };
      };
    }
  ];
}
