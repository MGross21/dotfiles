{ lib, pkgs, ... }:
{
  environment.extraOutputsToInstall = lib.mkForce [
    "man"
    "info"
  ];

  environment.systemPackages = with pkgs; [
    # Core utilities
    openvpn
    wget
    zip
    unzip
    rsync
    curl

    # Shell and terminal workflow
    zsh-completions
    zsh-history-substring-search

    # Terminal utilities
    gh
    less
    fzf
    neovim
    htop
    btop
    powertop
    fastfetch
    eza
    bat
    fd
    ripgrep
    speedtest-cli
    jq
    impala
    poppler
    poppler_data
    fontconfig
    vivid
    cava
    docker-compose
    man-db
    tldr
    bluetui
    ncdu
    dust
    gitui
    yazi
    bc
    kimun

    # Media/audio CLI utilities
    ffmpeg-full
    vulkan-tools
    pamixer
    alsa-utils
    claude-code
    claude-monitor
    clipse
    spotify-player

    efibootmgr
    mpv-unwrapped

    wl-clipboard
    usbutils
    pciutils
    psmisc
    inetutils

    # Extras
    fbcat
  ];
}
