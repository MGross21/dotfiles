{
  description = "MGross21 dotfiles NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    hyprland.url = "github:hyprwm/Hyprland";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      hyprland,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          (_: prev: { hyprland = hyprland.packages.${system}.hyprland; })
        ];
      };
      unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      formatter.${system} = pkgs.nixpkgs-fmt;

      # Host entries (managed by new_host_nix.sh)
      nixosConfigurations.msi = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit unstable;
        };
        modules = [
          ./hosts/msi/default.nix
        ];
      };
      # End host entries
    };
}
