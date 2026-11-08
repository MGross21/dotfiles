{
  description = "NixOS and nix-darwin configuration";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://hyprland.cachix.org"
      "https://cache.nixos-cuda.org"
      "https://mgross-nix.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      "mgross-nix.cachix.org-1:QZFb7AcOTcGiAHbhTAN4JbFubu+mXSANEBSDTCcHqsc="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    import-tree.url = "github:vic/import-tree";
    nixpkgs-materia.url = "github:NixOS/nixpkgs/nixos-25.05";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    preservation.url = "github:nix-community/preservation";
    srvos = {
      url = "github:nix-community/srvos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-colorizer.url = "github:nutsalhan87/nix-colorizer";
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
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
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    # Its prebuilt node segfaults against our nixpkgs; keep its own pin.
    openclaw.url = "github:openclaw/nix-openclaw";
    spotifast.url = "github:crmne/spotifast/v0.12.0";
    owly = {
      url = "github:t4t5/owly/9a676e11d011c34ea32798a2541f2b1eeb66e731";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rex = {
      url = "https://pkgs.superlogical.com/rex/nix/snapshot.tar.gz";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Plugin ABI is tied to one Hyprland release; bump in lockstep with nixpkgs' hyprland.
    hyprglass = {
      url = "github:hyprnux/hyprglass/v1.1.0";
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

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./parts);
}
