{ lib, ... }:
let
  toolchain =
    name:
    lib.mkEnableOption name
    // {
      default = true;
    };
in
{
  options.dev = {
    rust.enable = toolchain "Rust toolchain";
    python.enable = toolchain "Python toolchain";
    js.enable = toolchain "JavaScript toolchain";
    jvm.enable = toolchain "JVM / Kotlin toolchain";
    android.enable = toolchain "Android tooling";
    apple.enable = toolchain "Swift / iOS toolchain";
  };
}
