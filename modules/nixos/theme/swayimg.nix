{ config, lib, ... }:
let
  c = config.theming.colors;
  argb = alpha: color: lib.generators.mkLuaInline "0x${alpha}${lib.removePrefix "#" color}";
  solid = argb "ff";
  toLua = lib.generators.toLua { };

  fields = {
    text = {
      font = "JetBrainsMono Nerd Font";
      size = 18;
      color = solid c.fg;
      background = argb "cc" c.bg;
      shadow = argb "00" c.bg;
    };
    viewer.mark_color = solid c.blue;
    gallery = {
      window_color = solid c.bg;
      unselected_color = solid c.black;
      selected_color = solid c.black;
      border_color = solid c.blue;
    };
  };

  calls = {
    "viewer.set_window_background" = solid c.bg;
    "slideshow.set_window_background" = solid c.bg;
  };
in
lib.mkIf config.apps.media.enable {
  home-manager.sharedModules = [
    {
      programs.swayimg = {
        enable = true;
        initLua = lib.concatLines (
          lib.concatLists (
            lib.mapAttrsToList (
              section: lib.mapAttrsToList (k: v: "swayimg.${section}.${k} = ${toLua v}")
            ) fields
          )
          ++ lib.mapAttrsToList (fn: arg: "swayimg.${fn}(${toLua arg})") calls
        );
      };
    }
  ];
}
