{ lib, ... }:
{
  options.host.role = lib.mkOption {
    type = lib.types.enum [
      "workstation"
      "server"
    ];
    default = "workstation";
    description = "Interactive workstation or unattended server.";
  };
}
