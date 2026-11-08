{ lib, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    lib.mkIf (system == "x86_64-linux") {
      checks.llm-pool = pkgs.testers.runNixOSTest ../tests/llm-pool.nix;
    };
}
