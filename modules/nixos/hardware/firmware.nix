{ pkgs, ... }:
{
  hardware.enableRedistributableFirmware = true;
  services.fwupd.enable = true;
  hardware.firmware = with pkgs; [
    sof-firmware
  ];
}
