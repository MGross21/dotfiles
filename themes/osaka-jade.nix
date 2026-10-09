rec {
  # UI / semantic
  bg = "#111c18";
  fg = "#C1C497";
  cursor = "#F7E8B2";
  cursorText = "#111c18";
  bold = "#D6D5BC";
  selection = "#32473B";
  selectedText = "#F7E8B2";
  tab = "#2DD5B7";
  link = "#2DD5B7";
  badge = "#2DD5B7";

  # Named ANSI slots
  black = "#23372B";
  red = "#FF5345";
  green = "#549e6a";
  yellow = "#459451";
  blue = "#509475";
  magenta = "#D2689C";
  cyan = "#2DD5B7";
  white = "#C1C497";
  brightBlack = "#53685B";
  brightRed = "#db9f9c";
  brightGreen = "#63b07a";
  brightYellow = "#E5C736";
  brightBlue = "#ACD4CF";
  brightMagenta = "#75bbb3";
  brightCyan = "#8CD3CB";
  brightWhite = "#F7E8B2";

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
