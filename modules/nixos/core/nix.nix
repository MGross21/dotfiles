{ ... }:
{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    warn-dirty = false;

    cores = 0;
    max-jobs = "auto";

    auto-optimise-store = true;
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

  nixpkgs.config.allowUnfree = true;

  programs.nix-ld.enable = true;

  programs.nh = {
    enable = true;
    flake = "/home/mgross/dotfiles";
    clean.enable = true;
    clean.extraArgs = "--keep-since 7d --keep 5";
  };
}
