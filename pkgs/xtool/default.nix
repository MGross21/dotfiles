{
  lib,
  stdenv,
  appimageTools,
  fetchurl,
}:
let
  pname = "xtool";
  version = "1.24.0";
  arch = stdenv.hostPlatform.uname.processor;
  hashes = {
    x86_64 = "sha256-2/2dchbwd8hMFxtojEFzw3wjyna/f9GF0amuilPatZ8=";
    aarch64 = "sha256-S8BRX+1x77huglZPNY76DExtdr8bz9TF8lZye1PsWcg=";
  };
in
appimageTools.wrapType2 {
  inherit pname version;

  src = fetchurl {
    url = "https://github.com/xtool-org/xtool/releases/download/${version}/xtool-${arch}.AppImage";
    hash = hashes.${arch};
  };

  meta = {
    description = "Cross-platform Xcode replacement for building and installing iOS apps";
    homepage = "https://github.com/xtool-org/xtool";
    license = lib.licenses.mit;
    mainProgram = "xtool";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
