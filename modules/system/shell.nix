{ config, ... }:
{
  # Interactive setup lives in modules/home/shell.nix; compinit and the prompt run there.
  programs.zsh = {
    enable = true;
    enableGlobalCompInit = false;
    promptInit = "";
  };

  programs.ssh.knownHosts = config.sshKnownHosts;
}
