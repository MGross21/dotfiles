{ config, lib, ... }:
{
  options.gpu.nvidia.enable = lib.mkEnableOption "the NVIDIA driver with open kernel modules";

  config = lib.mkIf config.gpu.nvidia.enable {
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };
    hardware.nvidia = {
      open = true;
      nvidiaSettings = false;
    };
    services.xserver.videoDrivers = [ "nvidia" ];
    boot.blacklistedKernelModules = [ "nouveau" ];
  };
}
