{ config, lib, ... }:
let
  cfg = config.dotfiles;
in
{
  options.dotfiles.dir = lib.mkOption {
    type = lib.types.str;
    default = "${config.home.homeDirectory}/dotfiles";
    description = "Checkout of this repo; linked configs point into its working tree.";
  };

  config.xdg.configFile = lib.genAttrs [ "fastfetch" "cava" ] (name: {
    source = config.lib.file.mkOutOfStoreSymlink "${cfg.dir}/.config/${name}";
  });
}
