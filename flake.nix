{
  description = "MGross21 dotfiles NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-unstable.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixpkgs-unstable, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
      unstable = import nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };
    in {
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
