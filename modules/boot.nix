{
  config,
  pkgs,
  lib,
  ...
}:
{
  boot.loader = {
    timeout = 0; # skip menu (hold Space to show), silent handoff to plymouth
    systemd-boot = {
      enable = true;
      configurationLimit = 10; # cap boot entries
    };
    efi.canTouchEfiVariables = true; # systemd-boot needs its own NVRAM entry (GRUB owns the fallback BOOTX64.EFI)
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.initrd.systemd.enable = true; # parallel initrd
  boot.initrd.compressor = "zstd";
  boot.initrd.compressorArgs = [ "-19" "-T0" ];

  systemd.services.NetworkManager-wait-online.enable = false; # don't block boot on network

  boot.plymouth.enable = true; # splash hides grey boot log
  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
}
