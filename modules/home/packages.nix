{ lib, pkgs, ... }:
{
  home.extraOutputsToInstall = [ "man" ];

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

      jq
      tldr
      ncdu
      dust
      btop
      gitui
      speedtest-cli
      hyperfine
      nix-search-tv
      poppler
      poppler_data
      ffmpeg-full
      kimun
      kondo

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
