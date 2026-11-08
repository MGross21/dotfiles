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
      legacyPackages.configurations = pkgs.linkFarm "configurations" (nixos // darwin // home);

    };
}
