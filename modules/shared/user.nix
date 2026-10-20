{ lib, ... }:
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
    };

    email = lib.mkOption {
      type = lib.types.str;
      default = "mgrossofficial@gmail.com";
    };

    sshKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB2+Vgs3nf85+RXlfSC7r4sGfT7Zl4qVFYnW1RtbRQa3"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLGtw+U+bs3PlGQdtPohB+/ciRvZ3U+eZlzsEYIh7Ga mgross@msi"
      ];
    };
  };
}
