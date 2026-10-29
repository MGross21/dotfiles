{
  config,
  lib,
  pkgs,
  ...
}:
let
  accentHex = lib.removePrefix "#" config.theming.colors.blue;
in
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

  # Logitech G Pro keyboard (g810-led) and G502 Proteus Spectrum (OpenRGB).
  services.g810-led = {
    enable = true;
    profile = ''
      a ${accentHex}
      c
    '';
  };
  services.hardware.openrgb.enable = true;

  systemd.user.services.peripheral-theme = {
    description = "Apply peripheral RGB from active theme";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = [
        "${lib.getExe' pkgs.g810-led "gpro-led"} -p /etc/g810-led/profile"
        "${lib.getExe pkgs.openrgb} -d \"Logitech G502 Proteus Spectrum Gaming Mouse\" -m static -c ${accentHex}"
      ];
    };
  };
}
