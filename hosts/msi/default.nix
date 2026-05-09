{ config, pkgs, lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../configuration.nix
  ];

  networking.hostName = "msi";

  # MSI-specific kernel modules
  boot.extraModulePackages = [ config.boot.kernelPackages.msi-ec ];
  boot.kernelModules = lib.mkBefore [
    "msi-ec"
    "nvidia-drm"
    "acpi_backlight"
  ];
  boot.kernelParams = [ "mem_sleep_default=deep" "nologo" ];

  # AX210 WiFi suspend fix
  boot.extraModprobeConfig = ''
    options iwlwifi power_save=0
    options iwlmvm power_scheme=1 uapsd_disable=1
  '';

  # NVIDIA (MSI Optimus)
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    nvidiaSettings = true;
    prime = {
      offload.enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  boot.blacklistedKernelModules = [ "nouveau" ];
  environment.systemPackages = with pkgs; [
    libva
    libva-vdpau-driver
    libvdpau-va-gl
  ];

  # AX210 WiFi: prevent D3cold power-off, reload driver + unblock rfkill on resume
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x2725", ATTR{d3cold_allowed}="0"
  '';
  powerManagement.powerDownCommands = ''
    echo 0 > /sys/bus/pci/devices/0000:3d:00.0/d3cold_allowed
    ${pkgs.kmod}/bin/modprobe -r iwlmvm || true
    ${pkgs.kmod}/bin/modprobe -r iwlwifi || true
  '';

  powerManagement.resumeCommands = ''
    ${pkgs.kmod}/bin/modprobe iwlwifi
    sleep 1
    ${pkgs.kmod}/bin/modprobe iwlmvm
    ${pkgs.util-linux}/bin/rfkill unblock wifi
  '';

  # Battery charge thresholds (this battery)
  services.tlp.settings = {
    START_CHARGE_THRESH_BAT0 = 20;
    STOP_CHARGE_THRESH_BAT0 = 80;
  };
}
