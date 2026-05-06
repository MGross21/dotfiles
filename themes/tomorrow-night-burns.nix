rec {
  # UI / semantic
  bg           = "#151515";
  fg           = "#a1b0b8";
  cursor       = "#ff443e";
  cursorText   = "#708284";
  bold         = "#819090";
  selection    = "#b0bec5";
  selectedText = "#2a2d32";
  tab          = "#caa1a2";
  link         = "#ea4047";
  badge        = "#ff0000";

  # Named ANSI slots (for use in string interpolation)
  black         = "#252525";
  red           = "#832e31";
  green         = "#a63c40";
  yellow        = "#d3494e";
  blue          = "#fc595f";
  magenta       = "#df9395";
  cyan          = "#ba8586";
  white         = "#f5f5f5";
  brightBlack   = "#5d6f71";
  brightRed     = "#832e31";
  brightGreen   = "#a63c40";
  brightYellow  = "#d2494e";
  brightBlue    = "#fc595f";
  brightMagenta = "#df9395";
  brightCyan    = "#ba8586";
  brightWhite   = "#f5f5f5";

  # Ordered list for console.colors / any slot-indexed consumer
  # Index: 0=black 1=red 2=green 3=yellow 4=blue 5=magenta 6=cyan 7=white
  #        8=brBlack 9=brRed 10=brGreen 11=brYellow 12=brBlue 13=brMagenta 14=brCyan 15=brWhite
  ansi = builtins.map (builtins.substring 1 6) [
    black
    red
    green
    yellow
    blue
    magenta
    cyan
    white
    brightBlack
    brightRed
    brightGreen
    brightYellow
    brightBlue
    brightMagenta
    brightCyan
    brightWhite
  ];
}
