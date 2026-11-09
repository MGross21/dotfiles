{
  python3Packages,
  fetchFromGitHub,
  makeWrapper,
  hidapi,
  usbutils,
}:
python3Packages.buildPythonApplication {
  pname = "msi-perkeyrgb";
  version = "2.1";
  pyproject = true;
  build-system = [ python3Packages.setuptools ];
  src = fetchFromGitHub {
    owner = "Askannz";
    repo = "msi-perkeyrgb";
    rev = "e185a29e864bdda952b336940b047b5f97419d46";
    hash = "sha256-QG+Kchoy+kbg32EF0psnoowvmEVKnfIOsMcxR569RTg=";
  };
  nativeBuildInputs = [ makeWrapper ];
  postInstall = ''
          mkdir -p $out/libexec
          cat > $out/libexec/ldconfig << 'EOF'
    #!/bin/sh
    echo "  ${hidapi}/lib/libhidapi-hidraw.so.0"
    EOF
          chmod +x $out/libexec/ldconfig
          wrapProgram $out/bin/msi-perkeyrgb \
            --prefix PATH : $out/libexec \
            --prefix PATH : ${usbutils}/bin
  '';
}
