{ config, pkgs, lib, ... }:
let
  msi-perkeyrgb = pkgs.python3Packages.buildPythonApplication {
    pname = "msi-perkeyrgb";
    version = "2.1";
    pyproject = true;
    build-system = [ pkgs.python3Packages.setuptools ];
    src = pkgs.fetchFromGitHub {
      owner = "Askannz";
      repo = "msi-perkeyrgb";
      rev = "e185a29e864bdda952b336940b047b5f97419d46";
      sha256 = "0f25png4fcf7n07g57aa8nc2z3524ydx41b1vzh4dyij39r8lvs0";
    };
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postInstall = ''
      mkdir -p $out/libexec
      cat > $out/libexec/ldconfig << 'EOF'
#!/bin/sh
echo "  ${pkgs.hidapi}/lib/libhidapi-hidraw.so.0"
EOF
      chmod +x $out/libexec/ldconfig
      wrapProgram $out/bin/msi-perkeyrgb \
        --prefix PATH : $out/libexec
    '';
  };
in
{
  imports = [
    ./hardware-configuration.nix
    ../../configuration.nix
    ../../modules/desktop.nix
  ];

  networking.hostName = "msi";

  system.autoUpgrade = {
    enable = true;
    flake = "github:MGross21/dotfiles#msi";
    flags = [ "--update-input" "nixpkgs" ];
    dates = "daily";
    allowReboot = false;
  };

  # MSI-specific kernel modules
  boot.kernelModules = lib.mkBefore [
    "nvidia-drm"
    "ec_sys"
  ];
  boot.kernelParams = [ "mem_sleep_default=deep" "nologo" ];

  # AX210 WiFi suspend fix + ec_sys write access for MControlCenter
  boot.extraModprobeConfig = ''
    options iwlwifi power_save=0
    options iwlmvm power_scheme=1
    options ec_sys write_support=1
  '';

  # NVIDIA (MSI Optimus)
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true;
    nvidiaSettings = true;
    prime = {
      offload.enable = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };
  services.xserver.videoDrivers = [ "nvidia" ];
  boot.blacklistedKernelModules = [ "nouveau" ];
  environment.systemPackages = with pkgs; [
    libva
    libva-vdpau-driver
    libvdpau-va-gl
    msi-perkeyrgb
  ];

  # AX210 WiFi: prevent D3cold power-off, reload driver + unblock rfkill on resume
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x2725", ATTR{d3cold_allowed}="0"
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1038", ATTRS{idProduct}=="1122", MODE="0666"
  '';
  powerManagement.powerDownCommands = ''
    echo 0 > /sys/bus/pci/devices/0000:3d:00.0/d3cold_allowed
    ${pkgs.kmod}/bin/modprobe -r iwlmvm || true
    ${pkgs.kmod}/bin/modprobe -r iwlwifi || true
  '';

  powerManagement.resumeCommands = ''
    ${pkgs.kmod}/bin/modprobe iwlwifi
    sleep 1
    ${pkgs.kmod}/bin/modprobe iwlmvm
    ${pkgs.util-linux}/bin/rfkill unblock wifi
  '';

  # Battery charge thresholds (this battery)
  services.tlp.settings = {
    START_CHARGE_THRESH_BAT0 = 20;
    STOP_CHARGE_THRESH_BAT0 = 80;
  };

  programs.zsh.shellAliases.keycolor = "msi-perkeyrgb --model GS65 -s";
}
