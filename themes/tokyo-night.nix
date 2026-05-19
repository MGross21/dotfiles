rec {
  # UI / semantic
  bg           = "#1a1b26";
  fg           = "#a9b1d6";
  cursor       = "#7aa2f7";
  cursorText   = "#1a1b26";
  bold         = "#c0caf5";
  selection    = "#364a82";
  selectedText = "#c0caf5";
  tab          = "#bb9af7";
  link         = "#73daca";
  badge        = "#7aa2f7";

  # Named ANSI slots
  black         = "#16161e";
  red           = "#f7768e";
  green         = "#9ece6a";
  yellow        = "#e0af68";
  blue          = "#7aa2f7";
  magenta       = "#bb9af7";
  cyan          = "#73daca";
  white         = "#d5d6db";
  brightBlack   = "#444b6a";
  brightRed     = "#f7768e";
  brightGreen   = "#9ece6a";
  brightYellow  = "#e0af68";
  brightBlue    = "#7aa2f7";
  brightMagenta = "#bb9af7";
  brightCyan    = "#73daca";
  brightWhite   = "#d5d6db";

  # Index: 0=black 1=red 2=green 3=yellow 4=blue 5=magenta 6=cyan 7=white
  #        8=brBlack 9=brRed 10=brGreen 11=brYellow 12=brBlue 13=brMagenta 14=brCyan 15=brWhite
  ansi = builtins.map (builtins.substring 1 6) [
    black red green yellow blue magenta cyan white
    brightBlack brightRed brightGreen brightYellow brightBlue brightMagenta brightCyan brightWhite
  ];
}
