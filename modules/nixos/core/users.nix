{ pkgs, ... }:
{
  users.users.mgross = {
    isNormalUser = true;
    description = "Michael Gross";
    initialPassword = "changeme";
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
      "audio"
      "video"
      "dialout"
      "uucp"
      "input"
      "storage"
      "optical"
      "ollama"
    ];
    shell = pkgs.zsh;
  };

  home-manager.users.mgross = import ../../../home/mgross.nix;
}
