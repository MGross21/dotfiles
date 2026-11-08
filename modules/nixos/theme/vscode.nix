{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  id = "stylix.system-theme";
  c = config.theming.colors;
  template = import "${inputs.stylix}/modules/vscode/templates/theme.nix";
  cap = s: lib.toUpper (lib.substring 0 1 s) + lib.substring 1 (-1) s;

  inherit (inputs.nix-colorizer) hex oklch;
  lower = lib.toLower;
  root5 = a: lib.foldl' (y: _: (4 * y + a / (y * y * y * y)) / 5) 1.0 (lib.range 1 40);
  linear =
    x:
    if x <= 4.045e-2 then
      x / 12.92
    else
      let
        s = (x + 5.5e-2) / 1.055;
      in
      s * s * root5 (s * s);
  luminance =
    h:
    let
      c = hex.to.srgb h;
    in
    0.2126 * linear c.r + 0.7152 * linear c.g + 7.22e-2 * linear c.b;
  contrast =
    a: b:
    let
      la = luminance a;
      lb = luminance b;
    in
    (lib.max la lb + 5.0e-2) / (lib.min la lb + 5.0e-2);
  fit =
    target: bg: h:
    let
      shift = if luminance bg < 0.18 then hex.lighten else hex.darken;
      go =
        d:
        let
          x = lower (shift h d);
        in
        if d >= 1 || contrast x bg >= target then x else go (d + 2.0e-2);
    in
    if contrast h bg >= target then h else go 2.0e-2;

  degrees = 180 / 3.141592653589793;
  hue = h: (hex.to.oklch h).h * degrees;
  rotate = h: o: lower (oklch.to.hex (hex.to.oklch h // { h = (hue h + o) / degrees; }));
  abs = x: if x < 0 then -x else x;
  wrap =
    h:
    if h < 0 then
      h + 360
    else if h >= 360 then
      h - 360
    else
      h;
  hueGap =
    a: b:
    let
      d = abs (a - b);
    in
    lib.min d (360 - d);
  separate =
    minGap: p:
    let
      step =
        acc: n:
        let
          base = wrap (hue p.${n});
          clear = h: lib.all (o: hueGap h o >= minGap) acc.hues;
          offsets = lib.concatMap (k: [
            k
            (-k)
          ]) (map (k: k * 5.0) (lib.range 0 9));
          pick = lib.findFirst (o: clear (wrap (base + o))) 0.0 offsets;
          h = wrap (base + pick);
        in
        {
          hues = acc.hues ++ [ h ];
          out = acc.out // {
            ${n} = if pick == 0.0 then p.${n} else rotate p.${n} pick;
          };
        };
    in
    p
    // (lib.foldl' step
      {
        hues = [ ];
        out = { };
      }
      [
        "base0B"
        "base0D"
        "base0C"
        "base0E"
        "base08"
        "base09"
        "base0A"
        "base0F"
      ]
    ).out;

  floors = {
    base03 = 3.0;
  }
  // lib.genAttrs (map (s: "base0${s}") [
    "4"
    "8"
    "9"
    "A"
    "B"
    "C"
    "D"
    "E"
    "F"
  ]) (_: 4.5);
  legible = p: p // lib.mapAttrs (n: target: fit target p.base00 p.${n}) floors;
  raw = config.lib.stylix.colors.withHashtag;
  dark = legible raw;
  light = legible (
    separate 25 (
      raw
      // lib.listToAttrs (
        lib.imap0 (i: n: lib.nameValuePair "base0${toString n}" raw."base0${toString (7 - i)}") (
          lib.range 0 7
        )
      )
    )
  );

  ansi = lib.mergeAttrsList (
    map
      (n: {
        "terminal.ansi${cap n}" = c.${n};
        "terminal.ansiBright${cap n}" = c."bright${cap n}";
      })
      [
        "black"
        "red"
        "green"
        "yellow"
        "blue"
        "magenta"
        "cyan"
        "white"
      ]
  );

  variants = {
    dark = {
      colors = dark;
      uiTheme = "vs-dark";
      accent = lib.toLower config.theming.accent;
      overrides = ansi // {
        "editorCursor.foreground" = c.cursor;
        "terminalCursor.foreground" = c.cursor;
      };
    };
    light = {
      colors = light;
      uiTheme = "vs";
      accent = fit 4.5 light.base00 config.theming.accent;
      overrides = {
        "terminal.ansiBlack" = light.base06;
        "terminal.ansiBrightBlack" = light.base04;
        "terminal.ansiWhite" = light.base02;
        "terminal.ansiBrightWhite" = light.base01;
      };
    };
  };
  label = v: "System ${cap v}";
  mkTheme =
    v: d:
    let
      base = template { withHashtag = d.colors; };
    in
    base
    // {
      name = label v;
      type = v;
      tokenColors = base.tokenColors ++ [
        {
          scope = [
            "variable"
            "variable.other"
            "entity.name.variable.local"
            "meta.block variable.other"
          ];
          settings.foreground = d.colors.base05;
        }
        {
          scope = [
            "variable.parameter"
            "entity.name.variable.parameter"
          ];
          settings.foreground = d.colors.base0C;
        }
      ];
      colors =
        lib.mapAttrs (
          k: x: if x == d.colors.base0D && !lib.hasPrefix "terminal." k then d.accent else x
        ) base.colors
        // d.overrides;
    };

  ext = pkgs.linkFarm "vscode-system-theme" (
    {
      "package.json" = pkgs.writeText "package.json" (
        builtins.toJSON {
          name = "system-theme";
          displayName = "System Theme";
          version = "0.0.0";
          publisher = "stylix";
          categories = [ "Themes" ];
          engines.vscode = "^1.43.0";
          contributes.themes = lib.mapAttrsToList (v: d: {
            label = label v;
            inherit (d) uiTheme;
            path = "./themes/${v}.json";
          }) variants;
        }
      );
    }
    // lib.mapAttrs' (
      v: d:
      lib.nameValuePair "themes/${v}.json" (pkgs.writeText "${v}.json" (builtins.toJSON (mkTheme v d)))
    ) variants
  );
in
{
  home-manager.sharedModules = lib.mkIf config.apps.enable [
    {
      home.file.".vscode/extensions/${id}" = {
        source = ext;
        recursive = true;
      };
    }
  ];
}
