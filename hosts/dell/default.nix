{ inputs, pkgs, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "dell";

  dev = {
    rust.enable = true;
    python.enable = true;
    js.enable = true;
    jvm.enable = true;
    android.enable = true;
  };

  services.openclaw = {
    enable = true;
    package = inputs.openclaw.packages.${pkgs.stdenv.hostPlatform.system}.openclaw-gateway;
  };

  storage.disko = {
    enable = true;
    device = "/dev/sdc";
  };
}
