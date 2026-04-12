{ config, pkgs, ... }:
let
  homeDir = config.users.users.mgross.home;
in
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

  systemd.tmpfiles.rules = [
    "L ${homeDir}/.exports - mgross users - ${homeDir}/dotfiles/.exports"
    "L ${homeDir}/.config - mgross users - ${homeDir}/dotfiles/.config"
    "L+ ${homeDir}/Pictures - mgross users - ${homeDir}/dotfiles/Pictures"
  ];

  # Keep argv.json user-owned on NixOS to avoid root-owned VS Code config files.
  system.activationScripts.vscodeArgvJson.text = ''
        if [ -L "${homeDir}/.config/Code/argv.json" ]; then
          rm -f "${homeDir}/.config/Code/argv.json"
        fi

        install -d -m 0700 -o mgross -g users "${homeDir}/.config/Code"
        cat > "${homeDir}/.config/Code/argv.json" <<'EOF'
    {
      "password-store": "gnome-libsecret"
    }
    EOF
        chown mgross:users "${homeDir}/.config/Code/argv.json"
        chmod 0600 "${homeDir}/.config/Code/argv.json"
  '';
}
