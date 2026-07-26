{ openclaw-gateway, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../configuration.nix
    ../../modules/disko.nix
    ../../modules/openclaw.nix
  ];

  networking.hostName = "dell";

  dev = {
    rust.enable = true;
    python.enable = true;
    js.enable = true;
    jvm.enable = true;
    android.enable = true;
  };

  services.openclaw = {
    enable = true;
    package = openclaw-gateway;
  };

  disko.devices.disk.main.device = "/dev/sdc";
}
