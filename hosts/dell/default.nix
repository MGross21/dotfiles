{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../configuration.nix
    ../../modules/disko.nix
  ];

  networking.hostName = "dell";

  disko.devices.disk.main.device = "/dev/sdc";
}
