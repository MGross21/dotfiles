{
  pkgs,
  lib,
  ...
}:
{
  imports = [
    ./modules/theme.nix
    ./modules/boot.nix
    ./modules/system.nix
    ./modules/terminal.nix
    ./modules/users/mgross.nix
  ];

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

  system.stateVersion = "25.11";
}
