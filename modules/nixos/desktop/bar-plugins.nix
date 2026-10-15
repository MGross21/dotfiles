{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop.bar;

  resolve =
    p:
    let
      root = if p.dir == "." then p.src else "${p.src}/${p.dir}";
      manifest = lib.importJSON "${root}/manifest.json";
    in
    if !(builtins.elem "bar-widget" manifest.kinds) then
      throw "desktop.bar.plugins: ${p.id} is not a bar-widget plugin (kinds: ${toString manifest.kinds})"
    else
      {
        inherit (p) id settings;
        inherit root;
        entry = manifest.entryPoints.barWidget;
        section = if p.section != null then p.section else manifest.barWidget.defaultSection or "right";
      };

  plugins = map resolve cfg.plugins;

  layout = pkgs.writeText "bar-plugins-layout.json" (
    builtins.toJSON (map (p: removeAttrs p [ "root" ]) plugins)
  );

  pluginEntry = lib.types.submodule {
    options = {
      id = lib.mkOption {
        type = lib.types.str;
        description = "Plugin ID as listed on plugins.omarchy.org.";
      };
      src = lib.mkOption {
        type = lib.types.path;
        description = "Plugin source, usually a `flake = false` flake input.";
      };
      dir = lib.mkOption {
        type = lib.types.str;
        default = ".";
        description = "Directory within `src` holding manifest.json.";
      };
      section = lib.mkOption {
        type = lib.types.nullOr (
          lib.types.enum [
            "left"
            "center"
            "right"
          ]
        );
        default = null;
        description = "Bar island to place the widget in; null uses the manifest's defaultSection.";
      };
      settings = lib.mkOption {
        type = lib.types.attrsOf lib.types.anything;
        default = { };
        description = "Per-widget settings, passed to the plugin as `settings`.";
      };
    };
  };
in
{
  options.desktop.bar.plugins = lib.mkOption {
    type = lib.types.listOf pluginEntry;
    default = [ ];
    example = lib.literalExpression ''
      [
        {
          id = "io.github.raythurman2386.omamine";
          src = inputs.omamine;
        }
        {
          id = "yuters.flight-radar";
          src = inputs.flight-radar;
          section = "left";
        }
      ]
    '';
    description = ''
      Omarchy marketplace bar-widget plugins to load into the quickshell bar.
      Pin each as its own `flake = false` input; `nix flake update <input>` bumps it.
    '';
  };

  config = lib.mkIf (config.desktop.enable && config.desktop.environment == "hyprland") {
    environment.etc."xdg/quickshell/bar".source = pkgs.linkFarm "quickshell-bar" (
      map (name: {
        inherit name;
        path = "${config.programs.nh.flake}/.config/quickshell/bar/${name}";
      }) (builtins.attrNames (builtins.readDir ../../../.config/quickshell/bar))
      ++ [
        {
          name = "Ui";
          path = "${pkgs.omarchy-shell-compat}/Ui";
        }
        {
          name = "Commons";
          path = "${pkgs.omarchy-shell-compat}/Commons";
        }
        {
          name = "plugins";
          path = pkgs.linkFarm "quickshell-bar-plugins" (
            [
              {
                name = "layout.json";
                path = layout;
              }
            ]
            ++ map (p: {
              name = p.id;
              path = p.root;
            }) plugins
          );
        }
      ]
    );
  };
}
