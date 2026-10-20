{ inputs, overlay }:
let
  inherit (inputs.nixpkgs) lib;
in
{
  name,
  system ? "aarch64-darwin",
  modules ? [ ],
}:
inputs.nix-darwin.lib.darwinSystem {
  specialArgs = { inherit inputs; };
  modules = [
    {
      nixpkgs = {
        hostPlatform = system;
        overlays = [ overlay ];
        config.allowUnfree = true;
      };
    }
    inputs.home-manager.darwinModules.home-manager
    inputs.nix-homebrew.darwinModules.nix-homebrew
    inputs.stylix.darwinModules.stylix
    (import ./homeManager.nix { inherit inputs; })
    # Every file under modules/darwin must be a nix-darwin module; all are imported on every Mac.
    { imports = lib.filesystem.listFilesRecursive ../modules/darwin; }
    ../hosts/${name}/default.nix
  ]
  ++ modules;
}
