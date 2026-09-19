{
  callPackage,
  stdenvNoCC,
  src,
  bash,
  which,
  findutils,
  xcursorgen,
}:
let
  inkscapeShim = callPackage ./inkscape-shim.nix { };
in
stdenvNoCC.mkDerivation {
  pname = "MacTahoe-cursor-theme";
  version = "unstable-2024";
  inherit src;

  nativeBuildInputs = [
    bash
    which
    findutils
    xcursorgen
    inkscapeShim
  ];

  dontConfigure = true;
  buildPhase = ''
    runHook preBuild
    export HOME="$TMPDIR/home"
    export XDG_CACHE_HOME="$TMPDIR/cache"
    export XDG_CONFIG_HOME="$TMPDIR/config"
    mkdir -p "$HOME" "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME"
    cd cursors
    bash ./build.sh
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/icons/MacTahoe-cursors"
    mkdir -p "$out/share/icons/MacTahoe-dark-cursors"

    if [ -d cursors ]; then
      cursorBase="cursors"
    else
      cursorBase="."
    fi

    lightDist="$(find "$cursorBase" -maxdepth 1 -type d -name 'dist*' ! -name 'dist-dark*' | head -n 1)"
    darkDist="$(find "$cursorBase" -maxdepth 1 -type d -name 'dist-dark*' | head -n 1)"

    test -n "$lightDist"
    test -n "$darkDist"

    cp -r "$lightDist"/. "$out/share/icons/MacTahoe-cursors/"
    cp -r "$darkDist"/. "$out/share/icons/MacTahoe-dark-cursors/"
    runHook postInstall
  '';
}
