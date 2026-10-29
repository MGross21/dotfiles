{ config, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "pc";
  theming.name = "tokyo-night";

  desktop.enable = true;
  desktop.primaryMonitor = "DP-1";

  dev = {
    rust.enable = true;
    python.enable = true;
    js.enable = true;
    jvm.enable = true;
    android.enable = true;
    apple.enable = true;
  };

  apps = {
    enable = true;
    creative.enable = true;
    media.enable = true;
    gaming.enable = true;
  };

  # RTC shared with Windows on sdb.
  time.hardwareClockInLocalTime = true;

  # RTX 2070 (TU106)
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    nvidiaSettings = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  boot.blacklistedKernelModules = [ "nouveau" ];

  # min(RAM, 8 GiB); outranks the disk swap partition, which stays as overflow.
  zramSwap = {
    enable = true;
    memoryPercent = 100;
    memoryMax = 8 * 1024 * 1024 * 1024;
  };
  boot.kernel.sysctl."vm.swappiness" = 180;
  boot.kernel.sysctl."vm.page-cluster" = 0;

  storage.disko = {
    enable = true;
    device = "/dev/disk/by-id/usb-SABRENT_ROCKET-PRO_DD56419883C42-0:0";
  };
}
