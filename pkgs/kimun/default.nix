{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  openssl,
  writeShellApplication,
  curl,
  jq,
  gnused,
  gawk,
  nix,
}:
let
  version = "0.24.2";
  platforms = {
    x86_64-linux = "linux-x64";
    aarch64-linux = "linux-arm64";
    x86_64-darwin = "macos-x64";
    aarch64-darwin = "macos-arm64";
  };
  hashes = {
    linux-x64 = "sha256-qqfKZZZSQ72/n0KJfv0Ky/pRLY8GaOBgjWdaKiLPcqo=";
    linux-arm64 = "sha256-bUHAeOoqMq976r3PtjYnv9kkOCkIYVQdffT+N6ZjzPY=";
    macos-x64 = "sha256-E/x0LqQnNmjrwE14QMO4z0QEJd/cO5n9TCUSOYcgCgU=";
    macos-arm64 = "sha256-kdHmWUaDS8DJHWe/Ir4Ut1FY/I8Ibb4lK6yzM3flnF4=";
  };
  platform =
    platforms.${stdenv.hostPlatform.system}
      or (throw "kimun: unsupported system ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "kimun";
  inherit version;

  src = fetchurl {
    url = "https://github.com/nico2sh/kimun/releases/download/kimun-notes-v${version}/kimun-${version}-${platform}.tar.gz";
    hash = hashes.${platform};
  };

  sourceRoot = ".";

  nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    openssl
    stdenv.cc.cc.lib
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 kimun $out/bin/kimun
    runHook postInstall
  '';

  passthru.updateScript = writeShellApplication {
    name = "kimun-update";
    runtimeInputs = [
      curl
      jq
      gnused
      gawk
      nix
    ];
    text = ''
      file=pkgs/kimun/default.nix
      tag=$(curl -fsSL https://api.github.com/repos/nico2sh/kimun/releases \
        | jq -r '[.[] | select(.tag_name | startswith("kimun-notes-v"))][0].tag_name')
      ver=''${tag#kimun-notes-v}
      sums=$(curl -fsSL "https://github.com/nico2sh/kimun/releases/download/$tag/checksums-sha256.txt")
      sed -i "s|version = \".*\";|version = \"$ver\";|" "$file"
      for p in ${lib.concatStringsSep " " (lib.attrValues platforms)}; do
        hex=$(awk -v f="kimun-$ver-$p.tar.gz" '$2 == f { print $1 }' <<<"$sums")
        sri=$(nix hash convert --hash-algo sha256 --to sri "$hex")
        sed -i "s|$p = \"sha256-.*\";|$p = \"$sri\";|" "$file"
      done
      echo "kimun $ver"
    '';
  };

  meta = {
    description = "Terminal-based notes application with powerful search";
    homepage = "https://github.com/nico2sh/kimun";
    license = lib.licenses.mit;
    mainProgram = "kimun";
    platforms = lib.attrNames platforms;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
