{ config, ... }:
{
  services.usbmuxd.enable = config.dev.apple.enable;
}
