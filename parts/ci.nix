{ lib, self, ... }:
{
  perSystem =
    { pkgs, system, ... }:
    let
      forSystem = lib.filterAttrs (_: c: c.pkgs.stdenv.hostPlatform.system == system);
      nixos = lib.mapAttrs' (n: c: lib.nameValuePair "nixos-${n}" c.config.system.build.toplevel) (
        forSystem self.nixosConfigurations
      );
      darwin = lib.mapAttrs' (n: c: lib.nameValuePair "darwin-${n}" c.system) (
        forSystem self.darwinConfigurations
      );
      home = lib.mapAttrs' (n: c: lib.nameValuePair "home-${n}" c.activationPackage) (
        forSystem self.homeConfigurations
      );
    in
    {
      legacyPackages = {
        configurations = pkgs.linkFarm "configurations" (nixos // darwin // home);
        autoUpgrade = lib.mapAttrs (_: c: c.config.system.build.toplevel) (
          lib.filterAttrs (_: c: c.config.host.autoUpgrade or false) (forSystem self.nixosConfigurations)
        );
      };

      apps.cachix-push = {
        type = "app";
        program = lib.getExe (
          pkgs.writeShellApplication {
            name = "cachix-push";
            runtimeInputs = with pkgs; [
              cachix
              nix
              python3
            ];
            text = ''exec python3 ${../scripts/cachix-push.py} "$@"'';
          }
        );
        meta.description = "Push closures to Cachix without NVIDIA or CUDA paths";
      };
    };
}
