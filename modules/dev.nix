{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dev;
in
{
  options.dev = {
    rust.enable = lib.mkEnableOption "Rust toolchain" // { default = true; };
    python.enable = lib.mkEnableOption "Python toolchain" // { default = true; };
    js.enable = lib.mkEnableOption "JavaScript toolchain" // { default = true; };
    jvm.enable = lib.mkEnableOption "JVM / Kotlin toolchain" // { default = true; };
    android.enable = lib.mkEnableOption "Android tooling" // { default = true; };
  };

  config.environment.systemPackages =
    with pkgs;
    [
      gnumake
      clang
      llvm
      cmake
      nixfmt
    ]
    ++ lib.optionals cfg.rust.enable [
      cargo
      rustc
      rustfmt
      clippy
      rust-analyzer
      espflash
    ]
    ++ lib.optionals cfg.python.enable [
      uv
      pixi
      python3
    ]
    ++ lib.optionals cfg.js.enable [
      nodejs
    ]
    ++ lib.optionals cfg.jvm.enable [
      kotlin
      ktlint
      gradle
      jdk
    ]
    ++ lib.optionals cfg.android.enable [
      android-tools
    ];
}
