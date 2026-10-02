{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.desktop.bar;
  registry = lib.importJSON inputs.omarchy-plugins;

  resolve =
    p:
    let
      matches = builtins.filter (s: s ? plugins && s.plugins ? ${p.id}) registry.sources;
      source = builtins.head matches;
      src = builtins.fetchGit {
        url = source.repo;
        rev = source.listingValidatedCommit;
        ref = "refs/heads/${source.listingValidatedBranch}";
        shallow = true;
      };
      dir = dirOf (source.plugins.${p.id}.manifestPath or "manifest.json");
      root = if dir == "." then src else "${src}/${dir}";
      manifest = lib.importJSON "${root}/manifest.json";
    in
    if builtins.elem p.id registry.retiredPluginIds then
      throw "desktop.bar.plugins: ${p.id} was delisted from the Omarchy marketplace"
    else if matches == [ ] then
      throw "desktop.bar.plugins: ${p.id} is not listed on the Omarchy marketplace"
    else if !(builtins.elem "bar-widget" manifest.kinds) then
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
    type = lib.types.listOf (lib.types.coercedTo lib.types.str (id: { inherit id; }) pluginEntry);
    default = [ ];
    example = lib.literalExpression ''
      [
        "io.github.raythurman2386.omamine"
        { id = "yuters.flight-radar"; section = "left"; }
      ]
    '';
    description = ''
      Omarchy marketplace bar-widget plugins to load into the quickshell bar.
      Update the listing with `nix flake update omarchy-plugins`.
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
