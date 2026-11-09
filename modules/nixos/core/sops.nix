{
  config,
  inputs,
  lib,
  ...
}:
let
  # Hosts with a pinned hostKey are recipients in .sops.yaml.
  recipient = (config.hosts.${config.networking.hostName}.hostKey or null) != null;
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  config = lib.mkIf recipient {
    sops = {
      defaultSopsFile = ../../../secrets/secrets.yaml;
      secrets.user-password.neededForUsers = true;
    };

    users.mutableUsers = false;
    users.users.${config.user.name}.hashedPasswordFile = config.sops.secrets.user-password.path;
  };
}
