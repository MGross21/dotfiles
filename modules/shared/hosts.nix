{ config, lib, ... }:
let
  tailnet = "taile4fc1e.ts.net";
in
{
  options = {
    hosts = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            hostKey = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = null;
              description = "Host public key pinned in known_hosts.";
            };
            userKeys = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "User public keys authorized to log in.";
            };
          };
        }
      );
      default = { };
      description = "Known machines, keyed by hostname.";
    };

    sshKnownHosts = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      readOnly = true;
      description = "Known-hosts entries derived from `hosts`.";
    };
  };

  config = {
    hosts = {
      dell.hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMafvTWRzaRsCYklqRwx7LsjZlo+o2YdW9GJe7OUBLEE";
      msi = {
        hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINTp/wmRjY21qX9p1IwNhHZlKuMY/l0Bu3G66omK2rda";
        userKeys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLGtw+U+bs3PlGQdtPohB+/ciRvZ3U+eZlzsEYIh7Ga" ];
      };
      pc.hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAGf67qegk4FRDWRntylJsTg1D1Z/dWL6B78HgZY1DWq";
    };

    sshKnownHosts = lib.mapAttrs (name: h: {
      hostNames = [
        name
        "${name}.${tailnet}"
      ];
      publicKey = h.hostKey;
    }) (lib.filterAttrs (_: h: h.hostKey != null) config.hosts);
  };
}
