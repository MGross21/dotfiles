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
            };
            userKeys = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
            };
          };
        }
      );
      default = { };
      description = "Machines keyed by Tailscale name; hostKey pins the host, userKeys may log in.";
    };

    sshKnownHosts = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      readOnly = true;
      description = "programs.ssh.knownHosts entries derived from hosts.";
    };
  };

  config = {
    hosts = {
      dell.hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMafvTWRzaRsCYklqRwx7LsjZlo+o2YdW9GJe7OUBLEE";
      msi = {
        hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINTp/wmRjY21qX9p1IwNhHZlKuMY/l0Bu3G66omK2rda";
        userKeys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLGtw+U+bs3PlGQdtPohB+/ciRvZ3U+eZlzsEYIh7Ga" ];
      };
      pc = {
        hostKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMtNOq+jOKCE8llSUAX/eSDoY18rjKg/g41kau2mzz83";
        userKeys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB2+Vgs3nf85+RXlfSC7r4sGfT7Zl4qVFYnW1RtbRQa3" ];
      };
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
