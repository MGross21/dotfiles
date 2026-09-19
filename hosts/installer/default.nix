{
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
{
  system.stateVersion = "26.05";

  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
    settings.PermitEmptyPasswords = "yes";
  };
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
    inputs.disko.packages.${pkgs.stdenv.hostPlatform.system}.disko-install
    (pkgs.writeShellScriptBin "nixos-install-interactive" (
      builtins.readFile ../../scripts/iso-install.sh
    ))
  ];

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

  # Auto-launch installer when root logs in on console
  programs.bash.loginShellInit = ''
    if [[ "$(tty)" == /dev/tty1 ]] && [[ $EUID -eq 0 ]]; then
      nixos-install-interactive
    fi
  '';
}
