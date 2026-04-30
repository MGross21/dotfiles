# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running 'nixos-help').

{
  config,
  pkgs,
  lib,
  ...
}:

let
  unstable = import (builtins.fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") {
    system = pkgs.stdenv.hostPlatform.system;
    config = pkgs.config;
  };
in
{
  imports = [
    ./hosts/msi/hardware-configuration.nix
    ./modules/boot.nix
    ./modules/system.nix
    ./modules/terminal.nix
    # ./modules/desktops/gnome.nix
    ./modules/desktops/hyprland.nix
    ./modules/users/mgross.nix
  ];

  _module.args.unstable = unstable;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    warn-dirty = false;

    # Build tuning
    cores = 0; # all available
    max-jobs = "auto";

    # Store and download tuning
    auto-optimise-store = true;
    download-buffer-size = 67108864;

    # Binary cache sources
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
      "https://hyprland.cachix.org"
      "https://nix-gaming.cachix.org"
      "https://nixpkgs-wayland.cachix.org"
      "https://cuda-maintainers.cachix.org"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCUSDs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="
      "nixpkgs-wayland.cachix.org-1:3lwxazbmo/Kp5EbFd4aq+Z6ATkSTt6+yJIFQFwkqQQ8="
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];

    http-connections = 50;
    narinfo-cache-negative-ttl = 0;

    # Users allowed to administer the nix-daemon/store
    trusted-users = [
      "root"
      "@wheel"
    ];
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  nix.optimise.automatic = true;

  system.autoUpgrade = {
    enable = true;
    flake = "github:MGross21/dotfiles#msi";
    flags = [ "--update-input" "nixpkgs" ];
    dates = "daily";
    allowReboot = false;
  };

  time.timeZone = "America/Los_Angeles";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  programs.firefox.enable = true;

  system.stateVersion = "25.11";
}
