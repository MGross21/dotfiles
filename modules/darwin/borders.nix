{ lib, ... }:
{
  services.jankyborders = {
    enable = true;
    width = 2.0;
    style = "round";
    hidpi = true;
    inactive_color = lib.mkForce "0x00000000";
  };
}
