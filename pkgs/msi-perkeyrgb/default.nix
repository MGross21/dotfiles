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
    sha256 = "0f25png4fcf7n07g57aa8nc2z3524ydx41b1vzh4dyij39r8lvs0";
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
