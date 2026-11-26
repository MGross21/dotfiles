{ lib, pkgs, ... }:
{
  environment.extraOutputsToInstall = lib.mkForce [ "man" ];

  environment.systemPackages = with pkgs; [
    openvpn
    fontconfig
    docker-compose

    # Hardware and system TUIs
    powertop
    bluetui
    efibootmgr
    usbutils
    pciutils
    psmisc
    lsof
    smartmontools
    lm_sensors
    inetutils
    fbcat

    # Media/audio
    vulkan-tools
    pamixer
    alsa-utils
    mpv-unwrapped
    clipse
  ];
}
