{ config, lib, ... }:
let
  data = (import ../../themes).${config.theming.name};
in
{
  stylix = {
    enable = true;
    base16Scheme = data.yaml;
    image = data.wallpaper;
    polarity = "dark";
    fonts = { inherit (config.theming.fonts) sansSerif monospace serif; };
    homeManagerIntegration.autoImport = false;
  };

  services.jankyborders = {
    enable = true;
    width = 2.0;
    style = "round";
    hidpi = true;
    inactive_color = lib.mkForce "0x00000000";
  };
}
