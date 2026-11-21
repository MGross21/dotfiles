{ lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      app = description: drv: {
        type = "app";
        program = lib.getExe drv;
        meta = { inherit description; };
      };
    in
    {
      apps = {
        new-host = app "Scaffold a host directory and its hardware configuration" (
          pkgs.writeShellApplication {
            name = "new-host";
            runtimeInputs = [
              pkgs.coreutils
              pkgs.gnugrep
            ]
            ++ lib.optional pkgs.stdenv.hostPlatform.isLinux pkgs.util-linux;
            text = builtins.readFile ../scripts/new-host.sh;
          }
        );
      }
      // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
        ly-screenshot = app "Capture the framebuffer to a PNG" (
          pkgs.writeShellApplication {
            name = "ly-screenshot";
            inheritPath = false;
            runtimeInputs = with pkgs; [
              coreutils
              fbcat
              ffmpeg-headless
            ];
            text = builtins.readFile ../scripts/ly-screenshot.sh;
          }
        );
      };
    };
}
