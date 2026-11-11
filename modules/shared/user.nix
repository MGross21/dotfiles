{ config, lib, ... }:
{
  options.user = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "mgross";
      description = "Login name of the primary user.";
    };

    fullName = lib.mkOption {
      type = lib.types.str;
      default = "Michael Gross";
      description = "Display name of the primary user.";
    };

    email = lib.mkOption {
      type = lib.types.str;
      default = "mgrossofficial@gmail.com";
      description = "Email address of the primary user.";
    };

    sshKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = lib.concatMap (h: h.userKeys) (lib.attrValues config.hosts);
      description = "SSH public keys authorized for the primary user.";
    };
  };
}
