let
  wallpaperOf =
    file:
    builtins.path {
      path = ../Pictures/wallpapers + "/${file}";
      name = file;
    };
in
{
  tomorrow-night-burns = rec {
    colors = import ./tomorrow-night-burns.nix;
    accent = colors.blue;
    yaml = ./tomorrow-night-burns.yaml;
    wallpaper = wallpaperOf "windows11_red.png";
    nvim = "tomorrow-night-burns";
    ghostty = "Tomorrow Night Burns";
  };
  tokyo-night = rec {
    colors = import ./tokyo-night.nix;
    accent = colors.blue;
    yaml = ./tokyo-night.yaml;
    wallpaper = wallpaperOf "cosmic_bg.jpg";
    nvim = "tokyonight-storm";
    ghostty = "TokyoNight";
  };
  osaka-jade = rec {
    colors = import ./osaka-jade.nix;
    accent = colors.cyan;
    yaml = ./osaka-jade.yaml;
    wallpaper = wallpaperOf "green_jade.jpg";
    nvim = "bamboo";
    # No built-in Ghostty theme; modules/home/ghostty.nix generates one from colors.
    ghostty = null;
  };
}
