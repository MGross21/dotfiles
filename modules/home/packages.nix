{ lib, pkgs, ... }:
{
  home.extraOutputsToInstall = [
    "man"
    "info"
  ];

  home.packages = lib.filter (lib.meta.availableOn pkgs.stdenv.hostPlatform) (
    with pkgs;
    [
      wget
      zip
      unzip
      rsync
      curl
      less
      bc
      zsh-completions

      eza
      bat
      fd
      ripgrep
      jq
      tldr
      ncdu
      dust
      htop
      btop
      gitui
      fastfetch
      cava
      speedtest-cli
      nix-search-tv
      poppler
      poppler_data
      ffmpeg-full
      kimun

      claude-code
      claude-monitor
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      coreutils
      gnused
      findutils
    ]
  );
}
