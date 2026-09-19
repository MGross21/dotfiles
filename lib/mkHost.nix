{
  inputs,
  system,
  overlay,
}:
let
  inherit (inputs.nixpkgs) lib;
in
{
  name,
  modules ? [ ],
}:
lib.nixosSystem {
  inherit system;
  specialArgs = { inherit inputs; };
  modules = [
    { nixpkgs.overlays = [ overlay ]; }
    inputs.stylix.nixosModules.stylix
    inputs.disko.nixosModules.disko
    inputs.home-manager.nixosModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "hm-bak";
        extraSpecialArgs = { inherit inputs; };
      };
      stylix.homeManagerIntegration.autoImport = false;
    }
    # Every file under modules/nixos must be a NixOS module; all are imported on every host.
    { imports = lib.filesystem.listFilesRecursive ../modules/nixos; }
    ../hosts/${name}/default.nix
  ]
  ++ modules;
}
