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

  programs.zsh.enableLsColors = false;

  users.defaultUserShell = pkgs.zsh;
}
