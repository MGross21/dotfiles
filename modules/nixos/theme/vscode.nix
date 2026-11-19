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
  math = import "${inputs.nix-colorizer}/src/utils/math.nix";
  cap = s: lib.toUpper (lib.substring 0 1 s) + lib.substring 1 (-1) s;

  inherit (inputs.nix-colorizer) hex oklch;
  lower = lib.toLower;
  abs = x: if x < 0 then -x else x;
  pow = x: e: if x <= 0 then 0.0 else math.powFloat x e;

  luminance =
    h:
    let
      s = hex.to.srgb h;
    in
    0.2126729 * pow s.r 2.4 + 0.7151522 * pow s.g 2.4 + 0.072175 * pow s.b 2.4;
  isDark = h: luminance h < 0.18;
  # APCA 0.0.98G |Lc|
  contrast =
    text: bg:
    let
      soft = y: if y >= 0.022 then y else y + pow (0.022 - y) 1.414;
      t = soft (luminance text);
      b = soft (luminance bg);
      s = 1.14 * (if b > t then pow b 0.56 - pow t 0.57 else pow b 0.65 - pow t 0.62);
    in
    if abs s < 0.1 then 0 else (abs s - 0.027) * 100;
  fit =
    target: bg: h:
    let
      shift = if isDark bg then hex.lighten else hex.darken;
      go =
        d:
        let
          x = lower (shift h d);
        in
        if d >= 1 || contrast x bg >= target then x else go (d + 0.02);
    in
    if contrast h bg >= target then h else go 0.02;
  fitOn =
    target: bgs: h:
    lib.foldl' (x: bg: fit target bg x) h bgs;

  lch = hex.to.oklch;
  degrees = 180 / math.pi;
  hue = h: (lch h).h * degrees;
  rotate = h: o: lower (oklch.to.hex (lch h // { h = (hue h + o) / degrees; }));
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
          ]) (map (k: k * 5.0) (lib.range 0 8));
          pick = lib.findFirst (o: clear (wrap (base + o))) 0.0 offsets;
        in
        if (lch p.${n}).C < 0.03 then
          acc
        else
          {
            hues = acc.hues ++ [ (wrap (base + pick)) ];
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

  ramps = {
    dark = [
      0.22
      0.27
      0.33
      0.52
      0.72
      0.86
      0.91
      0.95
    ];
    light = [
      0.97
      0.92
      0.86
      0.68
      0.45
      0.3
      0.24
      0.18
    ];
  };
  derive =
    v: p:
    p
    // lib.listToAttrs (
      lib.imap0 (
        i: L:
        let
          n = "base0${toString i}";
          o = lch p.${n};
        in
        lib.nameValuePair n (
          lower (
            oklch.to.hex (
              o
              // {
                inherit L;
                C = lib.min o.C (if i < 3 then 0.025 else 0.04);
              }
            )
          )
        )
      ) ramps.${v}
    );

  raw = config.lib.stylix.colors.withHashtag;
  native = if isDark raw.base00 then "dark" else "light";
  text = {
    base04 = 60;
    base05 = 75;
  };
  syntax = lib.genAttrs (map (s: "base0${s}") [
    "8"
    "9"
    "A"
    "B"
    "C"
    "D"
    "E"
    "F"
  ]) (_: 60);
  palettes = lib.genAttrs [ "dark" "light" ] (
    v:
    let
      p = separate 25 (if v == native then raw else derive v raw);
    in
    p
    // lib.mapAttrs (n: target: fit target p.base00 p.${n}) syntax
    // lib.mapAttrs (n: target: fitOn target [ p.base00 p.base01 ] p.${n}) text
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
  overrides = {
    ${native} = ansi // {
      "editorCursor.foreground" = c.cursor;
      "terminalCursor.foreground" = c.cursor;
    };
  }
  // lib.optionalAttrs (native == "dark") {
    light = with palettes.light; {
      "terminal.ansiBlack" = base06;
      "terminal.ansiBrightBlack" = base04;
      "terminal.ansiWhite" = base02;
      "terminal.ansiBrightWhite" = base01;
    };
  }
  // lib.optionalAttrs (native == "light") { dark = { }; };

  uiTheme = {
    dark = "vs-dark";
    light = "vs";
  };
  label = v: "System ${cap v}";
  mkTheme =
    v:
    let
      p = palettes.${v};
      accent = fit 60 p.base00 config.theming.accent;
      muted = fitOn 45 [
        p.base00
        p.base01
      ] p.base03;
      raise = h: d: lower ((if v == "dark" then hex.lighten else hex.darken) h d);
      decor =
        k:
        lib.any (x: lib.hasPrefix x k) [
          "editorWhitespace"
          "editorOverviewRuler"
          "editorRuler"
          "minimap"
        ];
      recolor =
        k: x:
        if x == p.base0D && !lib.hasPrefix "terminal." k then
          accent
        else if x == p.base03 && lib.hasSuffix "oreground" k && !decor k then
          muted
        else
          x;
      dim =
        r:
        if
          lib.elem (r.settings.foreground or null) [
            p.base03
            "#00000050"
          ]
        then
          lib.recursiveUpdate r { settings.foreground = muted; }
        else
          r;
      base = template { withHashtag = p; };
    in
    base
    // {
      name = label v;
      type = v;
      semanticHighlighting = true;
      semanticTokenColors."*.deprecated".fontStyle = "strikethrough";
      tokenColors = map dim (
        base.tokenColors
        ++ [
          {
            scope = [
              "variable"
              "variable.other"
              "entity.name.variable.local"
              "meta.block variable.other"
            ];
            settings.foreground = p.base05;
          }
          {
            scope = [
              "variable.parameter"
              "entity.name.variable.parameter"
            ];
            settings.foreground = p.base0C;
          }
        ]
      );
      colors =
        lib.mapAttrs recolor base.colors
        // {
          "editor.findMatchBackground" = "${p.base0A}55";
          "editor.findMatchHighlightBackground" = "${p.base0A}26";
          "editor.wordHighlightStrongBackground" = "${accent}33";
          "diffEditor.insertedLineBackground" = "${p.base0B}1f";
          "diffEditor.insertedTextBackground" = "${p.base0B}40";
          "diffEditor.removedLineBackground" = "${p.base08}1f";
          "diffEditor.removedTextBackground" = "${p.base08}40";
          "editorCodeLens.foreground" = muted;
          "descriptionForeground" = p.base04;
          "button.secondaryBackground" = p.base02;
          "button.secondaryForeground" = p.base05;
          "button.secondaryHoverBackground" = raise p.base02 0.05;
        }
        // overrides.${v};
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
          contributes.themes = map (v: {
            label = label v;
            uiTheme = uiTheme.${v};
            path = "./themes/${v}.json";
          }) (lib.attrNames uiTheme);
        }
      );
    }
    // lib.mapAttrs' (
      v: _:
      lib.nameValuePair "themes/${v}.json" (pkgs.writeText "${v}.json" (builtins.toJSON (mkTheme v)))
    ) uiTheme
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
