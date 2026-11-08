{ config, lib, ... }:
lib.mkIf config.host.autoUpgrade {
  # CI moves `deploy` only after every auto-upgraded host's toplevel builds.
  system.autoUpgrade = {
    enable = lib.mkDefault true;
    flake = lib.mkDefault "github:MGross21/dotfiles/deploy#${config.networking.hostName}";
    upgrade = lib.mkDefault false;
    operation = lib.mkDefault (if config.host.role == "server" then "switch" else "boot");
    dates = lib.mkDefault "04:00";
    randomizedDelaySec = lib.mkDefault "30min";
  };

  alerts.units = [ "nixos-upgrade" ];
}
