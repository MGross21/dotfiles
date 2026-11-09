{ config, lib, ... }:
let
  data = (import ../../themes).${config.theming.name};
in
{
  stylix = {
    enable = true;
    base16Scheme = data.yaml;
    image = lib.mkDefault data.wallpaper;
    polarity = "dark";
    fonts = { inherit (config.theming.fonts) sansSerif monospace serif; };
    homeManagerIntegration.autoImport = false;
  };
}
