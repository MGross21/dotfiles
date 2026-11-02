{ pkgs, ... }:
{
  boot.loader = {
    timeout = 0;
    systemd-boot = {
      enable = true;
      configurationLimit = 5;
    };
    efi.canTouchEfiVariables = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.initrd.compressor = "zstd";
  boot.initrd.compressorArgs = [
    "-19"
    "-T0"
  ];

  systemd.services.NetworkManager-wait-online.enable = false;

  boot.tmp.cleanOnBoot = true;

  services.journald.settings.Journal.SystemMaxUse = "200M";

  boot.plymouth.enable = true;
  boot.consoleLogLevel = 0;
}
