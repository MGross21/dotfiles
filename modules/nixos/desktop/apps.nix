{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.apps;
  isX86_64 = pkgs.stdenv.hostPlatform.isx86_64;
in
{
  options.apps = {
    enable = lib.mkEnableOption "the optional application set";

    creative.enable = lib.mkEnableOption "Creative apps" // {
      default = true;
    };
    media.enable = lib.mkEnableOption "Media apps" // {
      default = true;
    };
    gaming.enable = lib.mkEnableOption "Gaming / chat apps" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = lib.mkOrder 100 (
      with pkgs;
      [
        vscode
      ]
      ++ lib.optionals cfg.creative.enable [
        obs-studio
        gimp
        rawtherapee
        kicad
      ]
      ++ lib.optionals cfg.media.enable [
        spotify
        spicetify-cli
        gthumb
        feh
      ]
      ++ lib.optionals (cfg.gaming.enable && isX86_64) [
        discord
        steam
      ]
    );
  };
}
