{ config, lib, ... }:
lib.mkIf (config.host.role == "server") {
  # CI moves `deploy` only after every server toplevel builds.
  system.autoUpgrade = {
    enable = lib.mkDefault true;
    flake = lib.mkDefault "github:MGross21/dotfiles/deploy#${config.networking.hostName}";
    upgrade = lib.mkDefault false;
    dates = lib.mkDefault "04:00";
    randomizedDelaySec = lib.mkDefault "30min";
  };
}
