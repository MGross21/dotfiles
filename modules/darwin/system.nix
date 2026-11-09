{ config, ... }:
let
  inherit (config) user;
in
{
  system.stateVersion = 6;
  system.primaryUser = user.name;

  users.users.${user.name}.home = "/Users/${user.name}";

  nix.settings.trusted-users = [ user.name ];

  security.pam.services.sudo_local.touchIdAuth = true;
}
