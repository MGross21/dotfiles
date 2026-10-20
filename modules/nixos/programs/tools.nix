{ lib, pkgs, ... }:
{
  environment.extraOutputsToInstall = lib.mkForce [
    "man"
    "info"
  ];

  environment.systemPackages = with pkgs; [
    openvpn
    man-db
    fontconfig
    docker-compose

    # Hardware and system TUIs
    powertop
    impala
    bluetui
    efibootmgr
    usbutils
    pciutils
    psmisc
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
