{
  stdenvNoCC,
  src,
  bash,
  coreutils,
  findutils,
  gnugrep,
  gnused,
  gtk3,
}:
stdenvNoCC.mkDerivation {
  pname = "MacTahoe-icon-theme";
  version = "unstable-2024";
  inherit src;

  # upstream ships a dangling symbolic-icon alias (globe->network-workgroup)
  dontCheckForBrokenSymlinks = true;

  nativeBuildInputs = [
    bash
    coreutils
    findutils
    gnugrep
    gnused
    gtk3
  ];

  dontConfigure = true;
  buildPhase = ''
    runHook preBuild
    export HOME="$TMPDIR/home"
    mkdir -p "$HOME"
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/icons"
    unset name
    bash ./install.sh -d "$out/share/icons" -n MacTahoe -t default
    test -n "$(find "$out/share/icons" -maxdepth 1 -type d -name 'MacTahoe*' | head -n 1)"
    runHook postInstall
  '';
}
