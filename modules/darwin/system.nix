{ config, ... }:
let
  inherit (config) user;
  home = "/Users/${user.name}";
in
{
  system.stateVersion = 6;
  system.primaryUser = user.name;

  users.users.${user.name}.home = home;
  programs.ssh.knownHosts = config.sshKnownHosts;
  home-manager.users.${user.name}.home.stateVersion = "25.11";

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ user.name ];
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  # Interactive setup lives in modules/home/shell.nix; compinit and the prompt run there.
  programs.zsh = {
    enable = true;
    enableGlobalCompInit = false;
    promptInit = "";
  };

  home-manager.sharedModules = [
    (
      { config, ... }:
      let
        dir = config.dotfiles.dir;
      in
      {
        programs.nh = {
          enable = true;
          flake = dir;
        };
        home.shellAliases = {
          update = "nix flake update --flake ${dir} && nh darwin switch ${dir}";
          nixrebuild = "nh darwin switch ${dir}";
        };
      }
    )
  ];
}
