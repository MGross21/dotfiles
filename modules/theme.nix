{ config, lib, ... }:
let
  wp = path: builtins.path { inherit path; name = baseNameOf path; };
  themes = {
    tomorrow-night-burns = {
      nix = import ../themes/tomorrow-night-burns.nix;
      yaml = ../themes/tomorrow-night-burns.yaml;
      wallpaper = wp ../Pictures/wallpapers/windows11_red.png;
      ghostty = "Tomorrow Night Burns";
      vivid = "tomorrow-night-burns";
      gtk = "Materia-dark-compact";
      icons = "Papirus-Dark";
      cursor = "macOS";
      nvim = "tomorrow-night-burns";
    };
    tokyo-night = {
      nix = import ../themes/tokyo-night.nix;
      yaml = ../themes/tokyo-night.yaml;
      wallpaper = wp ../Pictures/wallpapers/cosmic_bg.jpg;
      ghostty = "TokyoNight";
      vivid = "tokyonight-night";
      gtk = "Materia-dark-compact";
      icons = "Papirus-Dark";
      cursor = "macOS";
      nvim = "tokyonight-storm";
    };
  };

  data = themes.${config.theming.name};
  t = data.nix;
  rm = lib.removePrefix "#";
  ly = c: "0x00${rm c}";
in
{
  options.theming.name = lib.mkOption {
    type = lib.types.enum (builtins.attrNames themes);
    default = "tomorrow-night-burns";
    description = "Active color theme. Change + nixos-rebuild to switch all managed targets.";
  };

  config = {
    _module.args.theme = t;

    # ── stylix ─────────────────────────────────────────────────────────
    stylix = {
      enable = true;
      base16Scheme = data.yaml;
      image = lib.mkDefault data.wallpaper;
      polarity = "dark";
      targets = {
        console.enable = true; # vconsole 16-color palette
        grub.enable = false; # keep Sekiro grub theme
      };
    };

    # ── ly display-manager colors ───────────────────────────────────────
    services.displayManager.ly.settings = {
      bg = ly t.bg;
      fg = ly t.fg;
      border_fg = ly t.blue;
      error_bg = ly t.bg;
      error_fg = "0x01${rm t.red}";
      cmatrix_fg = ly t.green;
      cmatrix_head_col = "0x01FFFFFF";
      colormix_col1 = ly t.black;
      colormix_col2 = ly t.red;
      colormix_col3 = ly t.yellow;
      doom_top_color = ly t.red;
      doom_middle_color = ly t.yellow;
      doom_bottom_color = ly t.blue;
      gameoflife_fg = ly t.green;
    };

    # ── hyprland color overrides (loaded by pcall in hyprland.lua) ───
    environment.etc."hypr/colors.lua".text = ''
      THEME_ACTIVE   = "rgba(${rm t.blue}ff)"
      THEME_INACTIVE = "rgba(00000000)"
      THEME_SHADOW   = "rgba(${rm t.black}b3)"
    '';

    # ── ghostty built-in theme ─────────────────────────────────────────
    environment.etc."ghostty-theme.conf".text = ''
      theme = ${data.ghostty}
    '';

    # ── hyprpaper config (wallpaper follows active theme) ──────────────
    environment.etc."hypr/hyprpaper.conf".text = ''
      preload = ${toString data.wallpaper}

      wallpaper {
          monitor =
          path = ${toString data.wallpaper}
      }

      ipc = true
      splash = false
    '';

    # ── vivid LS_COLORS theme name ─────────────────────────────────────
    environment.variables.VIVID_THEME = data.vivid;

    # ── xsettingsd (GTK theme, icons, cursor for Wayland apps) ──────────
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

    # ── nvim colorscheme (sourced by lazy.lua at startup) ────────────────
    environment.etc."nvim-theme.lua".text = ''
      vim.cmd("colorscheme ${data.nvim}")
    '';

    # ── hyprlock (wallpaper + accent colors follow active theme) ──────────
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
          inner_color = rgba(${rm t.red}66)
          outline_color = rgba(${rm t.blue}e6)
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
          color = rgba(${rm t.blue}e6)
      }
    '';
  };
}
