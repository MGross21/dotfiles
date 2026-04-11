{ pkgs, lib, ... }:
let
  unstable = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") {
    system = pkgs.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };
  isX86_64 = pkgs.stdenv.hostPlatform.isx86_64;
in {
  networking.hostName = "msi";
  networking.networkmanager.enable = true;

  services.openssh.enable = true;
  services.gnome.gnome-keyring.enable = true;

  services.printing.enable = true;

  security.pam.services = {
    login.enableGnomeKeyring = true;
    ly.enableGnomeKeyring = true;
  };

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  security.sudo.enable = false;
  security."sudo-rs" = {
    enable = true;
    extraConfig = ''
      Defaults pwfeedback
    '';
  };

  environment.sessionVariables = {
    SUDO_PROMPT = "\${(L)USER} password: ";
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.logind.settings.Login = {
    LidSwitch = "ignore";
    LidSwitchExternalPower = "ignore";
    LidSwitchDocked = "ignore";
    IdleAction = "ignore";
    IdleActionSec = "0";
  };

  services.power-profiles-daemon.enable = false;
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;

      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";

      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";

      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "on";
    };
  };

  services.tailscale.enable = true;

  nixpkgs.config.allowUnfree = true;

  programs.thunar = {
    enable = true;
    plugins = with pkgs; [
      thunar-volman
      thunar-archive-plugin
      thunar-media-tags-plugin
      thunar-vcs-plugin
      thunar-shares-plugin
    ];
  };

  environment.systemPackages = with pkgs; [
    # Graphical terminal app
    unstable.ghostty

    # Graphical file manager stack
    gvfs
    # gvfs-mtp
    # gvfs-gphoto2
    # gvfs-afc
    # gvfs-smb
    tumbler

    # APPLICATIONS
    unstable.firefox
    feh
    mpv
    unstable.obs-studio
    kicad
    gimp
    rawtherapee
    gthumb
    libreoffice
    unstable.vscode
    unstable.spotify

    # GRAPHICS & MEDIA
    libxres
    gamemode
    xwayland
    qt5.qtbase
    qt5.qtwayland
    qt6.qtbase
    qt6.qtwayland

    # AUDIO
    pavucontrol

    # FONTS
    jetbrains-mono
    ubuntu-classic
    nerd-fonts.ubuntu
    nerd-fonts.jetbrains-mono
    nerd-fonts.symbols-only
    font-awesome
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-monochrome-emoji

    # SECURITY & UTILITIES
    libsecret
    seahorse
    hyprpolkitagent
    polkit_gnome
    mcontrolcenter

    # Notifications
    dunst
    
    # haskellPackages.cuda
  ] ++ lib.optionals isX86_64 (with pkgs; [
    # x86_64-only apps
    unstable.discord
    unstable.steam
    unstable.wine
    unstable.zoom-us
  ]);
}
