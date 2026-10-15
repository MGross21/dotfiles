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

  rgb =
    h:
    map (i: lib.fromHexString (lib.substring i 2 (lib.removePrefix "#" h)) / 255.0) [
      0
      2
      4
    ];
  toHex =
    cs:
    "#"
    + lib.concatMapStrings (
      x: lib.toLower (lib.fixedWidthString 2 "0" (lib.toHexString (builtins.floor (x * 255 + 0.5))))
    ) cs;
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
      l = map linear (rgb h);
    in
    0.2126 * lib.elemAt l 0 + 0.7152 * lib.elemAt l 1 + 7.22e-2 * lib.elemAt l 2;
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
      onDark = luminance bg < 0.18;
      go =
        f:
        let
          x = toHex (map (ch: if onDark then 1 - (1 - ch) * f else ch * f) (rgb h));
        in
        if f <= 0 || contrast x bg >= target then x else go (f - 2.0e-2);
    in
    go 1.0;

  abs = x: if x < 0 then -x else x;
  hsl =
    h:
    let
      ch = rgb h;
      r = lib.elemAt ch 0;
      g = lib.elemAt ch 1;
      b = lib.elemAt ch 2;
      mx = lib.max r (lib.max g b);
      mn = lib.min r (lib.min g b);
      d = mx - mn;
      l = (mx + mn) / 2;
      sector =
        if mx == r then
          (g - b) / d + (if g < b then 6 else 0)
        else if mx == g then
          (b - r) / d + 2
        else
          (r - g) / d + 4;
    in
    {
      inherit l;
      h = if d == 0 then 0.0 else 60 * sector;
      s = if d == 0 then 0.0 else d / (1 - abs (2 * l - 1));
    };
  fromHsl =
    {
      h,
      s,
      l,
    }:
    let
      hp = h / 60;
      chroma = (1 - abs (2 * l - 1)) * s;
      x = chroma * (1 - abs (hp - 2 * builtins.floor (hp / 2) - 1));
      m = l - chroma / 2;
      seg = builtins.floor hp;
      ch =
        if seg == 0 then
          [
            chroma
            x
            0
          ]
        else if seg == 1 then
          [
            x
            chroma
            0
          ]
        else if seg == 2 then
          [
            0
            chroma
            x
          ]
        else if seg == 3 then
          [
            0
            x
            chroma
          ]
        else if seg == 4 then
          [
            x
            0
            chroma
          ]
        else
          [
            chroma
            0
            x
          ];
    in
    toHex (map (v: v + m) ch);
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
          base = hsl p.${n};
          clear = h: lib.all (o: hueGap h o >= minGap) acc.hues;
          offsets = lib.concatMap (k: [
            k
            (-k)
          ]) (map (k: k * 5.0) (lib.range 0 9));
          pick = lib.findFirst (o: clear (wrap (base.h + o))) 0.0 offsets;
          h = wrap (base.h + pick);
        in
        {
          hues = acc.hues ++ [ h ];
          out = acc.out // {
            ${n} = if pick == 0.0 then p.${n} else fromHsl (base // { inherit h; });
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
