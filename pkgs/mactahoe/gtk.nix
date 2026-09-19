{
  stdenvNoCC,
  src,
  bash,
  sudo,
  which,
  coreutils,
  util-linux,
  procps,
  file,
  findutils,
  gnugrep,
  gnused,
  gawk,
  shadow,
  glibc,
  sassc,
  glib,
  libxml2,
  optipng,
}:
stdenvNoCC.mkDerivation {
  pname = "MacTahoe-gtk-theme";
  version = "unstable-2024";
  inherit src;

  nativeBuildInputs = [
    bash
    sudo
    which
    coreutils
    util-linux
    procps
    file
    findutils
    gnugrep
    gnused
    gawk
    shadow
    glibc.bin
    sassc
    glib
    libxml2
    optipng
  ];

  postPatch = ''
    substituteInPlace libs/lib-core.sh \
      --replace-fail 'MY_HOME=$(getent passwd "''${MY_USERNAME}" | cut -d: -f6)' 'MY_HOME="''${HOME}"'
  '';

  dontConfigure = true;
  buildPhase = ''
    runHook preBuild
    export HOME="$TMPDIR/home"
    export XDG_CACHE_HOME="$TMPDIR/cache"
    export XDG_CONFIG_HOME="$TMPDIR/config"
    export PATH="${glibc.bin}/bin:${shadow}/bin:$PATH"
    mkdir -p "$HOME"
    mkdir -p "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME"
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/share/themes"
    unset name
    bash ./install.sh -d "$out/share/themes" -n MacTahoe -t default -c dark
    test -n "$(find "$out/share/themes" -maxdepth 1 -type d -name 'MacTahoe*' | head -n 1)"
    runHook postInstall
  '';
}
