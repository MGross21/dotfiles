{ ... }:
{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "dell";

  boot.blacklistedKernelModules = [ "radeon" ];

  theming.name = "tokyo-night";

  host.role = "server";

  dev = {
    rust.enable = true;
    python.enable = true;
    js.enable = true;
    jvm.enable = true;
    android.enable = true;
    apple.enable = false;
  };

  storage.disko = {
    enable = true;
    device = "/dev/disk/by-id/ata-Samsung_SSD_850_EVO_500GB_S2RANX0HC29841Z";
  };
}
