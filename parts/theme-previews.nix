{ inputs, lib, ... }:
let
  themes = lib.attrNames (import ../themes);
  shots = [
    "login"
    "desktop"
    "apps"
  ];
in
{
  perSystem =
    { pkgs, system, ... }:
    lib.mkIf (system == "x86_64-linux") rec {
      legacyPackages.themePreviews = lib.genAttrs themes (
        theme:
        pkgs.testers.runNixOSTest (
          import ../tests/theme-preview.nix {
            inherit inputs lib theme;
          }
        )
      );

      apps.theme-previews = {
        type = "app";
        program = lib.getExe (
          pkgs.writeShellApplication {
            name = "theme-previews";
            text = ''
              [ -f flake.nix ] || { echo "run from the repo root" >&2; exit 1; }
            ''
            + lib.concatMapStrings (
              theme:
              lib.concatMapStrings (shot: ''
                install -Dm644 ${
                  legacyPackages.themePreviews.${theme}
                }/${shot}.png Pictures/screenshots/version3_3/${theme}_${shot}.png
              '') shots
            ) themes;
          }
        );
        meta.description = "Render README theme screenshots into Pictures/screenshots/version3_3";
      };
    };
}
