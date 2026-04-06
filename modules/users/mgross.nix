{ config, pkgs, ... }:
{
  users.users.mgross = {
    isNormalUser = true;
    description = "Michael Gross";
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
      "audio"
      "video"
      "uucp"
      "input"
      "storage"
      "optical"
      "ollama"
    ];
    packages = with pkgs; [ ];
    shell = pkgs.zsh;
  };

  environment.etc."vscode/argv.json".text = ''
    {
      "password-store": "gnome-libsecret"
    }
  '';

  systemd.tmpfiles.rules = [
    "d ${config.users.users.mgross.home}/.config/Code 0700 mgross users -"
    "L+ ${config.users.users.mgross.home}/.config/Code/argv.json - mgross users - /etc/vscode/argv.json"
  ];
}
