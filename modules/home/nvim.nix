{
  config,
  lib,
  pkgs,
  ...
}:
let
  themes = import ../../themes;
  inherit (config.dotfiles) mutable;

  # lazy.nvim rewrites these.
  lazyState = [
    "lazy-lock.json"
    "lazyvim.json"
  ];
  nvimSrc = ../../.config/nvim;
  storeConfig = builtins.path {
    path = nvimSrc;
    name = "dotfiles-nvim";
    filter = path: _: !(lib.elem (baseNameOf path) lazyState);
  };
in
{
  home.packages = [ pkgs.neovim ];

  xdg.configFile.nvim =
    if mutable then
      { source = config.lib.dotfiles.fromRepo ".config/nvim"; }
    else
      {
        source = storeConfig;
        recursive = true;
      };

  home.activation.seedLazyState = lib.mkIf (!mutable) (
    lib.hm.dag.entryAfter [ "linkGeneration" ] (
      lib.concatMapStrings (f: ''
        if [ ! -e "${config.xdg.configHome}/nvim/${f}" ]; then
          run install -Dm644 ${nvimSrc + "/${f}"} "${config.xdg.configHome}/nvim/${f}"
        fi
      '') lazyState
    )
  );

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
