{ ... }:
{
  networking.networkmanager.enable = true;
  networking.modemmanager.enable = false;
  networking.networkmanager.wifi.scanRandMacAddress = false;
  networking.firewall = {
    allowedTCPPorts = [
      8080
      24850 # input-sharing server
    ];
    allowedUDPPorts = [
      8081
      5353 # mDNS discovery
    ];
  };

  services.tailscale.enable = true;
}
