{
  stdenvNoCC,
  bash,
  python3,
  src,
  # Paths relative to shell/plugins; removed so the shell can never discover them.
  excludePlugins ? [ ],
}:
stdenvNoCC.mkDerivation {
  pname = "omarchy-shell";
  version = "4.5.0-rc2";
  inherit src;

  buildInputs = [
    bash
    python3
  ];

  dontBuild = true;

  installPhase = ''
    mkdir -p $out
    cp -r bin config default shell version icon.png $out
    chmod -R u+w $out
    for p in ${toString excludePlugins}; do rm -r "$out/shell/plugins/$p"; done
    substituteInPlace $out/shell/Commons/InputMethodState.qml \
      --replace-fail /usr/bin/python3 ${python3.interpreter}
  '';
}
