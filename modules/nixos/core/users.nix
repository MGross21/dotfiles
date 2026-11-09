{ config, lib, ... }:
let
  inherit (config) user;
in
{
  users.users.${user.name} = {
    isNormalUser = true;
    description = user.fullName;
    initialPassword = "changeme";
    openssh.authorizedKeys.keys = user.sshKeys;
    extraGroups = [
      "wheel"
      "networkmanager"
      "audio"
      "video"
      "dialout"
      "uucp"
      "input"
    ]
    ++ lib.optional config.virtualisation.docker.enable "docker"
    ++ lib.optional config.hardware.uinput.enable "uinput";
  };
}
