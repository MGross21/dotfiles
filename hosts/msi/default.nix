{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../configuration.nix
  ];

  networking.hostName = "msi";
}
