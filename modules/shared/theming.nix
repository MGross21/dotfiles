{
  config,
  lib,
  pkgs,
  ...
}:
let
  themes = import ../../themes;
  data = themes.${config.theming.name};
  font =
    role: package: name:
    lib.mkOption {
      type = lib.types.submodule {
        options = {
          package = lib.mkOption {
            type = lib.types.package;
            description = "Package providing the font.";
          };
          name = lib.mkOption {
            type = lib.types.str;
            description = "Font family name.";
          };
        };
      };
      default = { inherit package name; };
      description = "${role} font.";
    };
in
{
  options.theming = {
    name = lib.mkOption {
      type = lib.types.enum (builtins.attrNames themes);
      default = "tomorrow-night-burns";
      description = "Active color theme.";
    };

    colors = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = data.colors;
      description = "Palette of the active theme.";
    };

    accent = lib.mkOption {
      type = lib.types.str;
      default = data.accent;
      description = "Accent color of the active theme.";
    };

    firefoxProfile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null; # unthemed
      description = "Firefox profile directory, relative to the profiles root.";
    };

    fonts = {
      sansSerif = font "Sans-serif" pkgs.geist-font "Geist";
      monospace = font "Monospace" pkgs.nerd-fonts.jetbrains-mono "JetBrainsMono Nerd Font";
      serif = font "Serif" pkgs.noto-fonts "Noto Serif";
    };
  };
}
