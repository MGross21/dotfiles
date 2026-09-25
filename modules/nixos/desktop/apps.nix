{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.apps;
  isX86_64 = pkgs.stdenv.hostPlatform.isx86_64;
  spotifast =
    let
      pkg = inputs.spotifast.packages.${pkgs.stdenv.hostPlatform.system}.spotifast;
    in
    pkgs.runCommand "spotifast-${pkg.version}" { } ''
      mkdir -p $out/bin
      ln -s ${pkg}/bin/spotifast $out/bin/spotifast
      ln -s ${pkg}/bin/spotifast $out/bin/spotify
      ln -s ${pkg}/share $out/share
    '';
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
        spotifast
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
