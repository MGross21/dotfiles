{ config, lib, ... }:
let
  wp =
    path:
    builtins.path {
      inherit path;
      name = baseNameOf path;
    };
  themes = {
    tomorrow-night-burns = {
      nix = import ../../../themes/tomorrow-night-burns.nix;
      yaml = ../../../themes/tomorrow-night-burns.yaml;
      wallpaper = wp ../../../Pictures/wallpapers/windows11_red.png;
      ghostty = "Tomorrow Night Burns";
      vivid = "tomorrow-night-burns";
      gtk = "Materia-dark-compact";
      icons = "Papirus-Dark";
      cursor = "macOS";
      nvim = "tomorrow-night-burns";
      qs = with (import ../../../themes/tomorrow-night-burns.nix); {
        accent = blue;
        good = green;
        warn = yellow;
        urgent = badge;
      };
    };
    tokyo-night = {
      nix = import ../../../themes/tokyo-night.nix;
      yaml = ../../../themes/tokyo-night.yaml;
      wallpaper = wp ../../../Pictures/wallpapers/cosmic_bg.jpg;
      ghostty = "TokyoNight";
      vivid = "tokyonight-night";
      gtk = "Materia-dark-compact";
      icons = "Papirus-Dark";
      cursor = "macOS";
      nvim = "tokyonight-storm";
      qs = with (import ../../../themes/tokyo-night.nix); {
        accent = blue;
        good = green;
        warn = yellow;
        urgent = red;
      };
    };
  };

  data = themes.${config.theming.name};
  t = data.nix;
  c = config.theming.colors;
  rm = lib.removePrefix "#";
  ly = c: "0x00${rm c}";
in
{
  options.theming.name = lib.mkOption {
    type = lib.types.enum (builtins.attrNames themes);
    default = "tomorrow-night-burns";
    description = "Active color theme. Change + nixos-rebuild to switch all managed targets.";
  };

  options.theming.colors = lib.mkOption {
    type = lib.types.attrsOf (lib.types.either lib.types.str (lib.types.listOf lib.types.str));
    description = "Palette of the active theme. Individual slots can be overridden per host.";
  };

  config = {
    theming.colors = lib.mkDefault t;

    stylix = {
      enable = true;
      base16Scheme = data.yaml;
      image = lib.mkDefault data.wallpaper;
      polarity = "dark";
      targets = {
        console.enable = true;
        regreet.enable = false; # unused DM; silences a rename warning
      };
    };

    services.displayManager.ly.settings = {
      bg = ly c.bg;
      fg = ly c.fg;
      border_fg = ly c.blue;
      error_bg = ly c.bg;
      error_fg = "0x01${rm c.red}";
      cmatrix_fg = ly c.green;
      cmatrix_head_col = "0x01FFFFFF";
      colormix_col1 = ly c.black;
      colormix_col2 = ly c.red;
      colormix_col3 = ly c.yellow;
      doom_top_color = ly c.red;
      doom_middle_color = ly c.yellow;
      doom_bottom_color = ly c.blue;
      gameoflife_fg = ly c.green;
    };

    # Loaded by pcall from hyprland.lua.
    environment.etc."hypr/colors.lua".text = ''
      THEME_ACTIVE   = "rgba(${rm c.blue}ff)"
      THEME_INACTIVE = "rgba(00000000)"
      THEME_SHADOW   = "rgba(${rm c.black}b3)"
    '';

    environment.etc."quickshell/colors.json".text = builtins.toJSON {
      base = c.bg;
      fg = c.white;
      fgDim = c.brightBlack;
      inherit (data.qs)
        accent
        good
        warn
        urgent
        ;
    };

    environment.etc."ghostty-theme.conf".text = ''
      theme = ${data.ghostty}
    '';

    environment.etc."hypr/hyprpaper.conf".text = ''
      preload = ${toString data.wallpaper}

      wallpaper {
          monitor =
          path = ${toString data.wallpaper}
      }

      ipc = true
      splash = false
    '';

    environment.variables.VIVID_THEME = data.vivid;

    environment.etc."xsettingsd/xsettingsd.conf".text = ''
      Net/ThemeName "${data.gtk}"
      Net/IconThemeName "${data.icons}"
      Gtk/CursorThemeName "${data.cursor}"
      Net/EnableEventSounds 1
      EnableInputFeedbackSounds 0
      Xft/Antialias 1
      Xft/Hinting 1
      Xft/HintStyle "hintslight"
      Xft/RGBA "rgb"
    '';

    # Read by lua/config/theme.lua.
    environment.etc."nvim-theme.lua".text = ''
      return {
        name = "${data.nvim}",
        colors = {
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (k: v: ''${k} = "${v}",'') (lib.filterAttrs (_: lib.isString) c)
      )}
        },
      }
    '';

    environment.etc."hypr/hyprlock.conf".text = ''
      general {
          layer = overlay
      }

      background {
          monitor =
          path = ${toString data.wallpaper}
          blur_size = 3
          blur_passes = 5
      }

      image {
          monitor =
          path = $HOME/Pictures/profiles/man_on_moon.jpeg
          size = 120
          halign = center
          valign = center
          position = 0, 150
      }

      input-field {
          monitor =
          size = 320, 50
          halign = center
          valign = center
          position = 0, 0
          outline_thickness = 1
          dots_size = 0.3
          dots_spacing = 0.3
          dots_center = true
          fade_on_empty = true
          font_family = JetBrainsMono Nerd Font
          font_size = 18
          inner_color = rgba(${rm c.red}66)
          outline_color = rgba(${rm c.blue}e6)
          check_color = rgba(00c86400)
          fail_color = rgba(ff323200)
          text_color = rgba(ffffffe6)
      }

      label {
          monitor =
          text = cmd[update:1000] date '+%I:%M %p'
          halign = center
          valign = center
          position = 0, -100
          font_family = JetBrainsMono Nerd Font
          font_size = 30
          font_weight = bold
          color = rgba(${rm c.blue}e6)
      }
    '';
  };
}
