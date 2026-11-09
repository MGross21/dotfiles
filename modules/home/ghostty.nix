{
  config,
  lib,
  pkgs,
  ...
}:
let
  data = (import ../../themes).${config.theming.name};
  c = config.theming.colors;
  ansi = [
    "black"
    "red"
    "green"
    "yellow"
    "blue"
    "magenta"
    "cyan"
    "white"
  ];
  ansiOrder =
    ansi ++ map (n: "bright${lib.toUpper (lib.substring 0 1 n)}${lib.substring 1 (-1) n}") ansi;
in
{
  programs.ghostty = {
    enable = true;
    # macOS gets Ghostty from the Homebrew cask.
    package = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin null;
    systemd.enable = false;

    themes = lib.optionalAttrs (data.ghostty == null) {
      palette = {
        background = c.bg;
        foreground = c.fg;
        cursor-color = c.cursor;
        cursor-text = c.cursorText;
        selection-background = c.selection;
        selection-foreground = c.selectedText;
        palette = lib.imap0 (i: name: "${toString i}=${c.${name}}") ansiOrder;
      };
    };

    settings = {
      theme = if data.ghostty != null then data.ghostty else "palette";
      font-family = config.theming.fonts.monospace.name;
      font-size = 11;
      shell-integration = "zsh";
      term = "ghostty";
      title = "terminal";

      window-padding-x = 5;
      window-padding-y = 5;
      window-padding-balance = true;
      window-decoration = "auto";
      window-theme = "auto";

      link-previews = true;
      desktop-notifications = false;
      quit-after-last-window-closed = false;
      clipboard-paste-protection = true;
    };
  };
}
