{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  installShellFiles,
  writeShellApplication,
  curl,
  jq,
  gnused,
  nix,
}:
let
  version = "0.9";
  platforms = {
    x86_64-linux = "x86_64-unknown-linux-gnu";
    aarch64-linux = "aarch64-unknown-linux-gnu";
    x86_64-darwin = "x86_64-apple-darwin";
    aarch64-darwin = "aarch64-apple-darwin";
  };
  hashes = {
    x86_64-unknown-linux-gnu = "sha256-VviYkP1OFs9eEbshK7gStgqDGdq/sF+rr4DGyLUTO2U=";
    aarch64-unknown-linux-gnu = "sha256-Uxz8OB6FEwCHjiD3fr1Yck3cKOz15IvsZU9jDwv8f7A=";
    x86_64-apple-darwin = "sha256-qhUA4nXO/o2KfITvFzZ8APz/XeKy5ZXUvpHblA1p/x0=";
    aarch64-apple-darwin = "sha256-hH0vXY+yQtj8HrZLCPukuO2VZ773+3/yOnuMf9Efw7w=";
  };
  platform =
    platforms.${stdenv.hostPlatform.system}
      or (throw "kondo: unsupported system ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "kondo";
  inherit version;

  src = fetchurl {
    url = "https://github.com/tbillington/kondo/releases/download/v${version}/kondo-${platform}.tar.gz";
    hash = hashes.${platform};
  };

  sourceRoot = ".";

  nativeBuildInputs = [
    installShellFiles
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    install -Dm755 kondo $out/bin/kondo
    runHook postInstall
  '';

  dontAutoPatchelf = true;

  postInstall =
    lib.optionalString stdenv.hostPlatform.isLinux ''
      autoPatchelf $out
    ''
    + lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
      installShellCompletion --cmd kondo \
        --bash <($out/bin/kondo --completions bash) \
        --fish <($out/bin/kondo --completions fish) \
        --zsh <($out/bin/kondo --completions zsh)
    '';

  passthru.updateScript = writeShellApplication {
    name = "kondo-update";
    runtimeInputs = [
      curl
      jq
      gnused
      nix
    ];
    text = ''
      file=pkgs/kondo/default.nix
      rel=$(curl -fsSL https://api.github.com/repos/tbillington/kondo/releases/latest)
      ver=$(jq -r '.tag_name | ltrimstr("v")' <<<"$rel")
      sed -i "s|version = \".*\";|version = \"$ver\";|" "$file"
      for p in ${lib.concatStringsSep " " (lib.attrValues platforms)}; do
        hex=$(jq -r --arg n "kondo-$p.tar.gz" '.assets[] | select(.name == $n) | .digest | ltrimstr("sha256:")' <<<"$rel")
        sri=$(nix hash convert --hash-algo sha256 --to sri "$hex")
        sed -i "s|$p = \"sha256-.*\";|$p = \"$sri\";|" "$file"
      done
      echo "kondo $ver"
    '';
  };

  meta = {
    description = "Save disk space by cleaning non-essential files from software projects";
    homepage = "https://github.com/tbillington/kondo";
    license = lib.licenses.mit;
    mainProgram = "kondo";
    platforms = lib.attrNames platforms;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
