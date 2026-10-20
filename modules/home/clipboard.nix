{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
in
{
  options.clipboard = {
    copy = lib.mkOption {
      type = lib.types.str;
      default = if isDarwin then "pbcopy" else "wl-copy";
      description = "Command that reads stdin into the system clipboard.";
    };

    paste = lib.mkOption {
      type = lib.types.str;
      default = if isDarwin then "pbpaste" else "wl-paste";
      description = "Command that writes the system clipboard to stdout.";
    };
  };

  config = {
    home.packages = lib.optional (!isDarwin) pkgs.wl-clipboard;

    home.shellAliases = {
      clip = config.clipboard.copy;
      paste = config.clipboard.paste;
    };
  };
}
