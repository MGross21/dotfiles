{
  description = "Michael's NixOS configuration";

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
    nixpkgs-materia.url = "github:NixOS/nixpkgs/nixos-25.05";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    openclaw = {
      url = "github:openclaw/nix-openclaw";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nix-openclaw-tools.inputs.nixpkgs.follows = "nixpkgs";
    };
    # Plugin ABI is tied to one Hyprland release; bump in lockstep with nixpkgs' hyprland.
    hyprglass = {
      url = "github:hyprnux/hyprglass/v0.7.0";
      flake = false;
    };
    mactahoe-gtk = {
      url = "github:vinceliuice/MacTahoe-gtk-theme";
      flake = false;
    };
    mactahoe-icons = {
      url = "github:vinceliuice/MacTahoe-icon-theme";
      flake = false;
    };
  };

  outputs =
    inputs@{ nixpkgs, ... }:
    let
      system = "x86_64-linux";
      overlay = import ./pkgs {
        inherit (inputs) mactahoe-gtk mactahoe-icons nixpkgs-materia;
      };
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ overlay ];
      };
      mkHost = import ./lib/mkHost.nix { inherit inputs system overlay; };
      installerSystem = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          inputs.disko.nixosModules.disko
          ./hosts/installer/default.nix
        ];
      };
    in
    {
      formatter.${system} = pkgs.writeShellApplication {
        name = "fmt";
        runtimeInputs = [
          pkgs.nixfmt
          pkgs.git
        ];
        text = ''
          repo_files() {
            git ls-files '*.nix'
            git diff --cached --name-only --diff-filter=A | grep '\.nix$' || true
          }

          flags=()
          paths=()
          for arg in "$@"; do
            case "$arg" in
              -*) flags+=("$arg") ;;
              *)
                if [ -d "$arg" ]; then
                  mapfile -t -O "''${#paths[@]}" paths < <(repo_files | grep "^''${arg#./}" || true)
                else
                  paths+=("$arg")
                fi
                ;;
            esac
          done

          if [ "''${#paths[@]}" -eq 0 ]; then
            mapfile -t paths < <(repo_files)
          fi

          if [ "''${#paths[@]}" -eq 0 ]; then
            echo "fmt: no .nix files to format" >&2
            exit 0
          fi

          exec nixfmt ''${flags[@]+"''${flags[@]}"} "''${paths[@]}"
        '';
      };

      nixosConfigurations.installer = installerSystem;
      packages.${system} = {
        installer = installerSystem.config.system.build.isoImage;
        inherit (pkgs)
          msi-perkeyrgb
          papirus-red
          mactahoe-gtk-theme
          mactahoe-icon-theme
          mactahoe-cursor-theme
          ;
      };

      # Host entries (managed by new_host_nix.sh)
      nixosConfigurations.msi = mkHost { name = "msi"; };
      nixosConfigurations.dell = mkHost { name = "dell"; };
      # End host entries
    };
}
