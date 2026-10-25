{ ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    includes = [ "config.local" ];
    settings."*" = {
      SetEnv.TERM = "xterm-256color";
      ConnectTimeout = 10;
      ConnectionAttempts = 2;
      ServerAliveInterval = 60;
      ServerAliveCountMax = 3;
      ControlMaster = "auto";
      ControlPath = "~/.ssh/cm-%C";
      ControlPersist = "10m";
      AddKeysToAgent = "yes";
    };
  };
}
