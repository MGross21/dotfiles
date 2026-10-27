{ ... }:
{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "dell";

  boot.blacklistedKernelModules = [ "radeon" ];

  theming.name = "tokyo-night";

  system.autoUpgrade = {
    enable = true;
    flake = "github:MGross21/dotfiles#dell";
    dates = "04:00";
    randomizedDelaySec = "30min";
    persistent = true;
    allowReboot = false;
  };

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
