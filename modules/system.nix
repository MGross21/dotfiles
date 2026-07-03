{
  pkgs,
  lib,
  ...
}:
{
  networking.networkmanager.enable = true;
  networking.networkmanager.settings = {
    wifi = {
      "bg-scan" = false;
      "scan-rand-mac-address" = "no";
    };
  };
  networking.firewall.allowedUDPPorts = [ 8081 ];

  hardware.enableRedistributableFirmware = true;
  hardware.firmware = with pkgs; [
    sof-firmware
  ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.openssh.enable = true;
  programs.ssh.extraConfig = ''
    Host *
      SetEnv TERM=xterm-256color
      ConnectTimeout 10
      ConnectionAttempts 2
      ServerAliveInterval 60
      ServerAliveCountMax 3
      ControlMaster auto
      ControlPath ~/.ssh/cm-%C
      ControlPersist 10m
      AddKeysToAgent yes
  '';

  services.gnome.gnome-keyring.enable = true;

  security.pam.services.login.enableGnomeKeyring = true;

  security.sudo = {
    enable = true;
    extraConfig = ''
      Defaults pwfeedback
      Defaults passprompt="%u password: "
    '';
  };

  environment.sessionVariables = {
    SUDO_PROMPT = "%u password: ";
  };

  environment.extraOutputsToInstall = lib.mkForce [
    "man"
    "info"
  ];

  services.power-profiles-daemon.enable = false;
  services.tlp = {
    enable = true;
    settings = {
      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";

      WIFI_PWR_ON_AC = "off";
      WIFI_PWR_ON_BAT = "off";

      PCIE_ASPM_ON_BAT = "powersupersave";

      USB_AUTOSUSPEND = 1;

      SOUND_POWER_SAVE_ON_BAT = 1;
      SOUND_POWER_SAVE_CONTROLLER = "Y";

      NMI_WATCHDOG = 0;
    };
  };

  services.tailscale.enable = true;

  virtualisation.docker.enable = true;

  programs.nix-ld.enable = true;

  programs.nh = {
    enable = true;
    flake = "/home/mgross/dotfiles";
    clean.enable = true;
    clean.extraArgs = "--keep-since 7d --keep 5";
  };

  nixpkgs.config.allowUnfree = true;

  programs.ccache.enable = true; # C/C++ object cache across rebuilds

  environment.systemPackages = with pkgs; [
    mold # fastest linker (opt in per project: -fuse-ld=mold)
    ccache # C/C++ compile cache
    sccache # Rust/C/C++ compile cache
  ];
}
