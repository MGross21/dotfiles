{ inputs, pkgs, ... }:
{
  nix.settings = {
    min-free = 10 * 1024 * 1024 * 1024;
    max-free = 50 * 1024 * 1024 * 1024;

    download-buffer-size = 67108864;

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
  documentation.nixos.extraModules = [
    (inputs.import-tree ../../shared)
    (inputs.import-tree ../.)
  ];

  environment.systemPackages = with pkgs; [
    nix-du
    nix-heuristic-gc
    nix-tree
  ];

  programs.nix-ld.enable = true;

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 7d --keep 5";
  };
}
