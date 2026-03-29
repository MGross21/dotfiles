{ pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    # BASE PACKAGES
    # Core utilities
    networkmanager
    openvpn
    sudo
    git
    stow
    wget
    zip
    unzip

    # TERMINAL & SHELL
    ghostty
    tmux
    zsh
    zsh-completions
    zsh-syntax-highlighting
    zsh-autosuggestions
    zsh-history-substring-search

    # TERMINAL UTILITIES
    less
    fzf
    zoxide
    neovim
    htop
    btop
    nvtop  # GPU monitoring
    powertop
    fastfetch
    github-cli
    speedtest-cli
    poppler
    poppler_data
    vivid
    cava
    ripgrep
    fd
    bat
    docker
    docker-compose
    man-db
    tldr
    bluetui
    toilet
    eza

    # FILE MANAGER
    # File manager
    xfce.thunar
    xfce.thunar-volman
    xfce.thunar-archive-plugin
    xfce.thunar-media-tags-plugin
    xfce.thunar-vcs-plugin
    gvfs
    gvfs-mtp
    gvfs-gphoto2
    gvfs-afc
    gvfs-smb
    tumbler
    polkit-gnome
    # streamlink  # TODO: Check if in nixpkgs

    # APPLICATIONS
    firefox
    # spotify-launcher  # TODO: Check nixpkgs status
    feh
    mpv
    discord
    steam
    obs-studio
    kicad
    # openrgb  # TODO: Check nixpkgs - may require special setup
    gimp
    rawtherapee
    gthumb
    libreoffice-fresh
    # zoom  # TODO: Verify license status in nixpkgs
    vscode

    # GRAPHICS & MEDIA
    ffmpeg
    ffmpeg-full
    libxres
    gamemode
    vulkan-tools
    xwayland
    qt5.full
    qt6.full

    # DEVELOPMENT LANGUAGES
    rust
    rustup
    clang
    llvm
    cmake
    python3
    python312Packages.pip
    python312Packages.uv
    nodejs
    kotlin
    ktlint
    gradle
    jdk

    # AUDIO
    pipewire
    wireplumber
    pamixer
    pavucontrol
    helvum
    alsa-utils

    # FONTS
    jetbrains-mono
    ubuntu_font_family
    nerd-fonts
    font-awesome
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    noto-fonts-extra

    # THEMING
    nwg-look
    papirus-icon-theme
    gnome-themes-extra
    materia-gtk-theme
    # tela-circle-icon-theme  # TODO: Check nixpkgs

    # SECURITY & UTILITIES
    libsecret
    seahorse
    hyprpolkitagent

    # Power Management
    tlp
    # tlp-rdw  # TODO: Check if included with tlp in nixpkgs
    thermald

    # Notifications
    dunst

    # Android
    android-tools
    # android-sdk  # TODO: Complex setup - may need custom config

    # TODO: Packages to verify in nixpkgs
    # - spotify-launcher
    # - hyprshot
    # - waypaper
    # - spicetify-cli
    # - msi-perkeyrgb (likely broken/archived)
    # - gemini-cli
    # - clipse
    # - eww (can be installed but complex)
  ];

  # Configure Zsh
  programs.zsh.enable = true;

  # Git configuration
  programs.git.enable = true;
}