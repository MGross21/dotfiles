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
      system = pkgs.stdenv.hostPlatform.system;
      pkg = inputs.spotifast.packages.${system}.spotifast.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace src/app.rs --replace-fail "if self.settings.check_for_updates" "if false"
        '';
      });
      mesa = inputs.spotifast.inputs.nixpkgs.legacyPackages.${system}.mesa;
    in
    pkgs.runCommand "spotifast-${pkg.version}" { nativeBuildInputs = [ pkgs.makeWrapper ]; } ''
      mkdir -p $out/bin
      makeWrapper ${pkg}/bin/spotifast $out/bin/spotifast \
        --set __EGL_VENDOR_LIBRARY_FILENAMES ${mesa}/share/glvnd/egl_vendor.d/50_mesa.json \
        --prefix LD_LIBRARY_PATH : ${mesa}/lib
      ln -s $out/bin/spotifast $out/bin/spotify
      ln -s ${pkg}/share $out/share
    '';
in
{
  options.apps = {
    enable = lib.mkEnableOption "the optional application set";

    creative.enable = lib.mkEnableOption "creative apps" // {
      default = true;
    };
    media.enable = lib.mkEnableOption "media apps" // {
      default = true;
    };
    gaming.enable = lib.mkEnableOption "gaming and chat apps" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.localsend.enable = true;

    environment.systemPackages =
      with pkgs;
      [
        vscode
        t3code
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
      ]
      ++ lib.optionals (cfg.gaming.enable && isX86_64) [
        discord
        steam
      ];
  };
}
