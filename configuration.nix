
{ config, pkgs, lib, ... }:

{
  # METAMEMORY

  imports = [
    ./hardware-configuration.nix
    ./packages/system.nix
    ./packages/nvidia.nix
    ./packages/hyprland.nix
    ./packages/services.nix
  ];

  # System Version
  system.stateVersion = "25.11";
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowBroken = false;

  # BOOTLOADER

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";  # TODO: Update to your boot device
    # "nvidia_drm.modeset=1 rd.udev.log_priority=3 vt.global_cursor_default=0 iwlwifi.enable_ini=0 iwlwifi.d3_wake_disable=1"
    useOSProber = true;
    # theme = pkgs.fetchurl {
    #   url = "https://github.com/vinceliuice/Elegant-grub2-themes/releases/download/2024-10-20/Elegant-grub2-theme-2.4.zip";
    #   sha256 = ""; # TODO: Get hash from nix-prefetch-url
    # };
  };

  boot.loader.efi.canTouchEfiVariables = true;

  # NETWORKING 

  networking = {
    hostName = "nix";
    networkmanager.enable = true;
    nameservers = [ "1.1.1.1" "8.8.8.8" ];
  };

  # TIME

  time.timeZone = "America/Los_Angeles"; 
  i18n.defaultLocale = "en_US.UTF-8";

  # AUDIO

  # Enable PipeWire audio
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Bluetooth support
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # SECURITY   

  # UFW Firewall
  networking.firewall.enable = false;  # TODO: Configure UFW if preferred
  # networking.firewall.allowedTCPPorts = [ ];
  # networking.firewall.allowedUDPPorts = [ ];

  # Allow sudo without password for wheel group (optional)
  # security.sudo.wheelNeedsPassword = false;

  # KeyRing
  services.gnome-keyring.enable = true;
  security.pam.services.gdm.enableGnomeKeyring = true;

  # USERS

  users.users.mgross = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
      "audio"
      "video"
      "uucp"
      "input"
      "storage"
      "optical"
      "ollama"
    ];
    shell = pkgs.zsh;
  };

  # WM (HYPRLAND)
  programs.hyprland.enable = true;
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";  # Wayland support for Electron apps
  };

  # START   

  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = true;

  # SYSTEMD USER SERVICES
  systemd.user.services = {
    # tlp-sleep = {
    #   description = "TLP power manager";
    #   serviceConfig = {
    #     Type = "oneshot";
    #     ExecStart = "${pkgs.tlp}/bin/tlp start";
    #   };
    #   wantedBy = [ "multi-user.target" ];
    # };
  };
}