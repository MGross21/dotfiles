{
  inputs,
  lib,
  ...
}:
let
  hostDirs = lib.attrNames (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../hosts)
  );
  darwinHosts = [ "mac" ];
  nixosHosts = lib.subtractLists (darwinHosts ++ [ "installer" ]) hostDirs;

  mkInstaller =
    system:
    lib.nixosSystem {
      specialArgs = { inherit inputs; };
      modules = [
        { nixpkgs.hostPlatform = system; }
        "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        inputs.disko.nixosModules.disko
        ../modules/system/nix.nix
        ../modules/shared/user.nix
        ../modules/shared/hosts.nix
        ../hosts/installer
      ];
    };
in
{
  flake.nixosConfigurations =
    lib.genAttrs nixosHosts (
      name:
      lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          inputs.stylix.nixosModules.stylix
          inputs.disko.nixosModules.disko
          inputs.home-manager.nixosModules.home-manager
          (inputs.import-tree ../modules/system)
          (inputs.import-tree ../modules/nixos)
          ../hosts/${name}
        ];
      }
    )
    // {
      installer = mkInstaller "x86_64-linux";
      installer-aarch64 = mkInstaller "aarch64-linux";
    };

  flake.darwinConfigurations = lib.genAttrs darwinHosts (
    name:
    inputs.nix-darwin.lib.darwinSystem {
      specialArgs = { inherit inputs; };
      modules = [
        { nixpkgs.hostPlatform = "aarch64-darwin"; }
        inputs.home-manager.darwinModules.home-manager
        inputs.nix-homebrew.darwinModules.nix-homebrew
        inputs.stylix.darwinModules.stylix
        (inputs.import-tree ../modules/system)
        (inputs.import-tree ../modules/darwin)
        ../hosts/${name}
      ];
    }
  );
}
