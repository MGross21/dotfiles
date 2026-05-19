{
  description = "MGross21 dotfiles NixOS configuration";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://hyprland.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    hyprland.url = "github:hyprwm/Hyprland";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      hyprland,
      disko,
      stylix,
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
          stylix.nixosModules.stylix
          disko.nixosModules.disko
          ./hosts/msi/default.nix
        ];
      };
      nixosConfigurations.dell = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit unstable;
        };
        modules = [
          stylix.nixosModules.stylix
          disko.nixosModules.disko
          ./hosts/dell/default.nix
        ];
      };
      # End host entries
    };
}
