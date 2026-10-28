{
  description = "NixOS and nix-darwin configuration";

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
    preservation.url = "github:nix-community/preservation";
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    openclaw = {
      url = "github:openclaw/nix-openclaw";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nix-openclaw-tools.inputs.nixpkgs.follows = "nixpkgs";
    };
    spotifast.url = "github:crmne/spotifast/v0.12.0";
    owly = {
      url = "github:t4t5/owly/9a676e11d011c34ea32798a2541f2b1eeb66e731";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Plugin ABI is tied to one Hyprland release; bump in lockstep with nixpkgs' hyprland.
    hyprglass = {
      url = "github:hyprnux/hyprglass/v0.7.0";
      flake = false;
    };
    xdph-remote = {
      url = "github:spotdemo4/xdg-desktop-portal-hyprland";
      flake = false;
    };
    omarchy = {
      url = "github:omacom/omarchy/v4.5.0-rc2";
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
      inherit (nixpkgs) lib;
      system = "x86_64-linux";
      overlay = import ./pkgs {
        inherit (inputs)
          mactahoe-gtk
          mactahoe-icons
          nixpkgs-materia
          omarchy
          ;
      };
      pkgsFor =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ overlay ];
        };
      pkgs = pkgsFor system;
      forAllSystems =
        f:
        lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
          "aarch64-darwin"
        ] (s: f (pkgsFor s));
      mkHost = import ./lib/mkHost.nix { inherit inputs system overlay; };
      mkHome = import ./lib/mkHome.nix { inherit inputs overlay; };
      mkDarwin = import ./lib/mkDarwin.nix { inherit inputs overlay; };
      mkInstaller =
        system:
        lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            { nixpkgs.hostPlatform = system; }
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            inputs.disko.nixosModules.disko
            ./modules/shared/user.nix
            ./modules/shared/hosts.nix
            ./hosts/installer/default.nix
          ];
        };
      installer = mkInstaller "x86_64-linux";
      installer-aarch64 = mkInstaller "aarch64-linux";
    in
    {
      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);

      nixosConfigurations = { inherit installer installer-aarch64; };
      packages.${system} = {
        installer = installer.config.system.build.isoImage;
        inherit (pkgs)
          kimun
          msi-perkeyrgb
          mactahoe-gtk-theme
          mactahoe-icon-theme
          mactahoe-cursor-theme
          ;
      };
      packages.aarch64-linux.installer = installer-aarch64.config.system.build.isoImage;

      # Host entries (managed by new_host_nix.sh)
      nixosConfigurations.msi = mkHost { name = "msi"; };
      nixosConfigurations.dell = mkHost { name = "dell"; };
      nixosConfigurations.pc = mkHost { name = "pc"; };
      nixosConfigurations.usb = mkHost {
        name = "usb";
        modules = [ inputs.preservation.nixosModules.preservation ];
      };
      # End host entries

      darwinConfigurations.mac = mkDarwin { name = "mac"; };

      homeConfigurations =
        let
          user = (lib.evalModules { modules = [ ./modules/shared/user.nix ]; }).config.user.name;
        in
        lib.mapAttrs'
          (
            host: system:
            lib.nameValuePair "${user}@${host}" (mkHome {
              name = "${user}@${host}";
              inherit system;
            })
          )
          {
            wsl = "x86_64-linux";
            wsl-arm = "aarch64-linux";
          };
    };
}
