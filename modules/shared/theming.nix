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
    package: name:
    lib.mkOption {
      type = lib.types.submodule {
        options = {
          package = lib.mkOption { type = lib.types.package; };
          name = lib.mkOption { type = lib.types.str; };
        };
      };
      default = { inherit package name; };
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
      type = lib.types.attrsOf (lib.types.either lib.types.str (lib.types.listOf lib.types.str));
      default = data.colors;
      description = "Palette of the active theme.";
    };

    accent = lib.mkOption {
      type = lib.types.str;
      default = data.accent;
      description = "Accent color of the active theme.";
    };

    fonts = {
      sansSerif = font pkgs.geist-font "Geist";
      monospace = font pkgs.nerd-fonts.jetbrains-mono "JetBrainsMono Nerd Font";
      serif = font pkgs.noto-fonts "Noto Serif";
    };
  };
}
