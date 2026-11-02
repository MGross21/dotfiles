{
  config,
  lib,
  pkgs,
  ...
}:
{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    warn-dirty = false;

    cores = lib.mkDefault 0;
    max-jobs = lib.mkDefault "auto";

    min-free = 10 * 1024 * 1024 * 1024;
    max-free = 50 * 1024 * 1024 * 1024;

    download-buffer-size = 67108864;
    accept-flake-config = true;

    http-connections = 50;
    narinfo-cache-negative-ttl = 0;

    trusted-users = [
      "root"
      "@wheel"
    ];
  };

  nix.optimise.automatic = true;
  nix.channel.enable = false;

  documentation.doc.enable = false;
  documentation.info.enable = false;

  environment.systemPackages = with pkgs; [
    nix-du
    nix-heuristic-gc
    nix-tree
  ];

  nixpkgs.config.allowUnfree = true;

  programs.nix-ld.enable = true;

  programs.nh = {
    enable = true;
    flake = lib.mkIf (
      config.host.role == "workstation"
    ) config.home-manager.users.${config.user.name}.dotfiles.dir;
    clean.enable = true;
    clean.extraArgs = "--keep-since 7d --keep 5";
  };
}
