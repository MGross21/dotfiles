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
  config.home.packages =
    with pkgs;
    [
      gnumake
      clang
      llvm
      cmake
      nixfmt
    ]
    # Language servers and formatters for nvim; mason is disabled there.
    ++ [
      tree-sitter
      clang-tools # clangd, clang-format
      lua-language-server
      stylua
      nixd
      statix
      bash-language-server
      shellcheck
      shfmt
      taplo
      marksman
      yaml-language-server
      vscode-langservers-extracted # jsonls, html, cssls
    ]
    ++ lib.optionals cfg.rust.enable [
      cargo
      rustc
      rustfmt
      clippy
      rust-analyzer
      espflash
      sccache
    ]
    ++ lib.optionals cfg.python.enable [
      uv
      pixi
      python315
      pyright
      ruff
    ]
    ++ lib.optionals cfg.js.enable [
      nodejs
      vtsls
      eslint_d
      prettierd
    ]
    ++ lib.optionals cfg.jvm.enable [
      kotlin
      kotlin-language-server
      ktlint
      gradle
      jdk
    ]
    ++ lib.optionals cfg.android.enable [
      android-tools
    ]
    ++ lib.optionals cfg.apple.enable [
      swiftlint
      swift-format
    ]
    # Darwin uses the Xcode toolchain for swift and sourcekit-lsp.
    ++ lib.optionals (cfg.apple.enable && stdenv.hostPlatform.isLinux) [
      swift
      swiftpm
      sourcekit-lsp
      xtool
      libimobiledevice
    ]
    ++ lib.optionals (cfg.apple.enable && stdenv.hostPlatform.isDarwin) [
      xcodegen
      xcbeautify
    ]
    ++ lib.optional stdenv.hostPlatform.isLinux mold;

  # rust-analyzer needs stdlib sources; nixpkgs rustc ships none.
  config.home.sessionVariables = lib.mkIf cfg.rust.enable {
    RUST_SRC_PATH = "${pkgs.rustPlatform.rustLibSrc}";
    RUSTC_WRAPPER = "sccache";
  };
}
