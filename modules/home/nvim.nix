{
  config,
  lib,
  pkgs,
  ...
}:
let
  themes = import ../../themes;
in
{
  home.packages = [ pkgs.neovim ];

  xdg.configFile.nvim.source = config.lib.file.mkOutOfStoreSymlink "${config.dotfiles.dir}/.config/nvim";

  # Read by .config/nvim/lua/config/theme.lua.
  xdg.configFile."nvim-theme.lua".text = ''
    return ${
      lib.generators.toLua { } {
        name = themes.${config.theming.name}.nvim;
        colors = lib.filterAttrs (_: lib.isString) config.theming.colors;
      }
    }
  '';
}
