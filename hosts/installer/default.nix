{
  pkgs,
  lib,
  config,
  ...
}:
{
  system.stateVersion = "26.05";

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };
  users.users.root.openssh.authorizedKeys.keys = config.user.sshKeys;
  boot.zfs.forceImportRoot = false;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    accept-flake-config = true;
  };
  nix.extraOptions = ''
    warn-dirty = false
  '';

  # Keeps the in-RAM /nix store overlay from OOMing while building the closure.
  zramSwap = {
    enable = true;
    memoryPercent = 150;
  };

  environment.systemPackages = with pkgs; [
    git
    curl
    vim
    parted
    gptfdisk
    disko
  ];

  services.getty.autologinUser = lib.mkForce "root";

  networking.networkmanager.enable = true;
  networking.wireless.enable = lib.mkForce false;

  documentation.enable = false;
  documentation.nixos.enable = false;
  i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];
  hardware.enableAllFirmware = lib.mkForce false;
  hardware.enableRedistributableFirmware = true;

  image.baseName = lib.mkForce "nixos_${config.system.nixos.release}_${pkgs.stdenv.hostPlatform.system}";
  isoImage.squashfsCompression = "zstd -Xcompression-level 19";
  isoImage.includeSystemBuildDependencies = false;
}
