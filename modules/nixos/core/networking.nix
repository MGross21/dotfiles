{ ... }:
{
  networking.networkmanager.enable = true;
  networking.modemmanager.enable = false;
  networking.networkmanager.settings = {
    wifi = {
      "bg-scan" = false;
      "scan-rand-mac-address" = "no";
    };
  };
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
