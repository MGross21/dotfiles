{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = lib.optional config.services.tailscale.enable (
    pkgs.writeShellApplication {
      name = "ares";
      runtimeInputs = [
        pkgs.tailscale
        pkgs.openssh
      ];
      text = ''
        tailscale status >/dev/null 2>&1 || sudo tailscale up
        exec ssh ares
      '';
    }
  );

  # Interactive setup lives in modules/home/shell.nix; compinit and the prompt run there.
  programs.zsh = {
    enable = true;
    enableGlobalCompInit = false;
    enableLsColors = false;
    promptInit = "";
  };

  users.defaultUserShell = pkgs.zsh;
}
