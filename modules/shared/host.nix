{ config, lib, ... }:
{
  options.host = {
    role = lib.mkOption {
      type = lib.types.enum [
        "workstation"
        "server"
      ];
      default = "workstation";
      description = "Interactive workstation or unattended server.";
    };
    autoUpgrade = lib.mkOption {
      type = lib.types.bool;
      default = config.host.role == "server";
      description = "Pull the CI-approved config from the deploy branch.";
    };
  };
}
