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
    allowedTCPPorts = [ 8080 ];
    allowedUDPPorts = [ 8081 ];
  };

  services.tailscale.enable = true;
}
