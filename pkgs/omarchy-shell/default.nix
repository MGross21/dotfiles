{
  lib,
  stdenvNoCC,
  bash,
  python3,
  src,
  # Paths relative to shell/plugins; removed so the shell can never discover them.
  excludePlugins ? [ ],
  # Translation codes under default/i18n to keep.
  languages ? [ "en" ],
  # bin/ scripts kept besides those the shell reaches.
  keepBins ? [ "omarchy-shell" ],
}:
stdenvNoCC.mkDerivation {
  pname = "omarchy-shell";
  version = "4.5.0";
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
    find $out/default/i18n -mindepth 1 -maxdepth 1 ${
      lib.concatMapStringsSep " " (n: "! -name ${n}") (
        languages
        ++ [
          "locales.json"
          "plural.jq"
        ]
      )
    } -exec rm -r {} +
    bash ${./prune-bin.sh} $out ${lib.escapeShellArgs keepBins}
    substituteInPlace $out/shell/Commons/InputMethodState.qml \
      --replace-fail /usr/bin/python3 ${python3.interpreter}
    substituteInPlace $out/shell/plugins/agents/Panel.qml \
      --replace-fail 'if (!blankSlate) {' 'if (false) {' \
      --replace-fail 'visible: root.addStage === "" && !root.blankSlate' 'visible: false'
  '';
}
