{
  writeShellScriptBin,
  librsvg,
}:
# cursor build.sh calls `inkscape -o out.png -w W -h H in.svg`; only that form is handled.
writeShellScriptBin "inkscape" ''
  out= w= h= svg=
  while [ $# -gt 0 ]; do
    case "$1" in
      -o) out="$2"; shift 2 ;;
      -w) w="$2"; shift 2 ;;
      -h) h="$2"; shift 2 ;;
      *.svg) svg="$1"; shift ;;
      *) shift ;;
    esac
  done
  [ -n "$h" ] || h="$w"
  exec ${librsvg}/bin/rsvg-convert -w "$w" -h "$h" -o "$out" "$svg"
''
