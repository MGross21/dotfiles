{ config, lib, ... }:
let
  id = "dotfiles.session";
in
{
  config = lib.mkIf config.desktop.omarchy.enable {
    desktop.omarchy.plugins.${id} = {
      source = ".config/omarchy/plugins/${id}";
      barSection = "right";
      barPosition = "last";
    };
  };
}
