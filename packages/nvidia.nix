{ config, pkgs, ... }:

{
  # NVIDIA DRIVERS
  hardware.nvidia = {
    # Ensure NVIDIA driver is installed
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = false;
    
    # Use the open-source kernel module (NVK) when possible
    # Set to false to use proprietary nvidia kernel module
    open = false;
    
    # Newer cards should use nouveau, but NVIDIA cards may need the proprietary driver
    nvidiaSettings = true;
  };

  # For Hyprland with NVIDIA
  # hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;  # Uncomment for older cards

  # Enable graphics support
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;  # For 32-bit applications (gaming)
  };

  # Ensure 32-bit support packages
  environment.systemPackages = with pkgs; [
    libva
    libva-vdpau-driver
    libvdpau-va-gl
  ];

  boot.kernelModules = [ "nvidia-drm" ];
}