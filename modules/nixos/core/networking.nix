{ ... }:
{
  networking.networkmanager.enable = true;
  networking.modemmanager.enable = false;
  networking.networkmanager.wifi.scanRandMacAddress = false;

  services.tailscale.enable = true;
}
