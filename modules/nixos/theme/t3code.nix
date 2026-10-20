{
  config,
  lib,
  pkgs,
  ...
}:
let
  c = config.theming.colors;
  accent = config.theming.accent;
  surface = canvas: {
    inherit canvas;
    chrome = canvas;
    toolbar = canvas;
    terminalBackground = canvas;
  };
  theme = pkgs.writeText "t3code-nixos-theme.json" (
    builtins.toJSON {
      name = "NixOS";
      appearance = "dark";
      canvas = c.bg;
      inherit accent;
      colors = {
        terminalBackground = c.bg;
        terminalForeground = c.fg;
        terminalCursor = c.cursor;
      };
      variants.light = surface c.brightWhite // {
        inherit accent;
        terminalForeground = c.bg;
        terminalCursor = accent;
      };
    }
  );
  t3 = lib.getExe' pkgs.t3code "t3";
  jq = lib.getExe pkgs.jq;
in
{
  # Must be a regular file; T3 ignores symlinked themes.
  home-manager.sharedModules = lib.mkIf config.apps.enable [
    (
      { lib, ... }:
      {
        home.activation.t3codeTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          dir="$HOME/.t3/userdata/themes"
          run install -Dm644 ${theme} "$dir/.nixos.json.tmp"
          run mv -f "$dir/.nixos.json.tmp" "$dir/nixos.json"
          if [ "$(${jq} -r .defaultTheme "$HOME/.t3/userdata/settings.json" 2>/dev/null)" != nixos ]; then
            run ${t3} theme set nixos
          fi
        '';
      }
    )
  ];
}
