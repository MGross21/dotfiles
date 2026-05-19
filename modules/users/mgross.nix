{ config, pkgs, ... }:
let
  homeDir = config.users.users.mgross.home;
  vscodeTheme = pkgs.fetchFromGitHub {
    owner = "MGross21";
    repo  = "vscode-tomorrow-night-burns";
    rev   = "fa722503c82a455c4131071a0b101aeecbb68313";
    sha256 = "05g6a9nr8nqf2aj4gcvblxpp8i86n12y41b3hvfknjgijxliip2b";
  };
in
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
    packages = with pkgs; [ ];
    shell = pkgs.zsh;
  };

  systemd.tmpfiles.rules = [
    "L ${homeDir}/.config - mgross users - ${homeDir}/dotfiles/.config"
    "L+ ${homeDir}/Pictures - mgross users - ${homeDir}/dotfiles/Pictures"
  ];

  system.activationScripts.vscodeTheme.text = ''
    install -d -m 0700 -o mgross -g users "${homeDir}/.vscode/extensions"
    ln -sfn ${vscodeTheme} "${homeDir}/.vscode/extensions/alii.vscode-tomorrow-night-burns-master"
    chown -h mgross:users "${homeDir}/.vscode/extensions/alii.vscode-tomorrow-night-burns-master"
  '';

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
