{ config, pkgs, ... }:
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
      "docker"
      "audio"
      "video"
      "dialout"
      "uucp"
      "input"
      "uinput"
      "storage"
      "optical"
      "ollama"
    ];
    shell = pkgs.zsh;
  };

  home-manager.users.${user.name}.home.stateVersion = "25.11";
}
