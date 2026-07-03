{
  config,
  pkgs,
  lib,
  theme,
  ...
}:
let
  accentHex = lib.removePrefix "#" theme.blue;
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
              --prefix PATH : $out/libexec \
              --prefix PATH : ${pkgs.usbutils}/bin
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
  theming.name = "tomorrow-night-burns";

  boot.kernelModules = lib.mkBefore [
    "nvidia-drm"
    "ec_sys" # required by MControlCenter for EC access
  ];
  boot.kernelParams = [
    "mem_sleep_default=deep"
    "nologo"
    "i915.enable_psr=2" # UHD 630 panel self-refresh — reduces display power draw
    "i915.enable_fbc=1" # framebuffer compression — less VRAM bandwidth
    "nmi_watchdog=0" # prevents periodic NMI wakeups from interrupting sleep
    "mitigations=off" # single-user trusted machine — disable CPU vuln mitigations for perf
  ];

  boot.extraModprobeConfig = ''
    options iwlwifi power_save=0
    options iwlmvm power_scheme=1 d0i3_disable=1 uapsd_disable=1
    options ec_sys write_support=1
    options snd_hda_intel power_save=1
    options snd_hda_intel power_save_controller=y
    options nvidia NVreg_DynamicPowerManagement=0x02
  '';

  # GTX 1660 Ti Mobile (TU116M) + Intel UHD 630 — PRIME offload, iGPU renders desktop
  hardware.graphics.enable = true;
  hardware.graphics.enable32Bit = true;
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;
    powerManagement.enable = true;
    powerManagement.finegrained = true; # RTD3 — dGPU powers off between offload launches
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

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x2725", ATTR{d3cold_allowed}="0"
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1038", ATTRS{idProduct}=="1122", MODE="0666"
  '';

  # AX210 (0x2725) enters D3cold on suspend and hard-crashes — unload before sleep, reload after.
  # powerManagement.powerDownCommands runs at shutdown, not suspend — use sleep.target hook instead.
  systemd.services.ax210-suspend = {
    description = "Unload AX210 WiFi driver before suspend, reload after resume";
    before = [ "sleep.target" ];
    wantedBy = [ "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "ax210-pre-suspend" ''
        echo 0 > /sys/bus/pci/devices/0000:3d:00.0/d3cold_allowed
        ${pkgs.kmod}/bin/modprobe -r iwlmvm || true
        ${pkgs.kmod}/bin/modprobe -r iwlwifi || true
      '';
      ExecStop = pkgs.writeShellScript "ax210-post-resume" ''
        ${pkgs.kmod}/bin/modprobe iwlwifi
        sleep 2
        ${pkgs.kmod}/bin/modprobe iwlmvm
        ${pkgs.util-linux}/bin/rfkill unblock wifi
      '';
    };
  };

  services.displayManager.ly.settings.battery_id = "BAT1";
  services.thermald.enable = true;

  # auto-cpufreq owns governor — switches powersave↔performance based on load+AC state
  # TLP handles energy policy/boost/platform profile; governors left to auto-cpufreq
  services.auto-cpufreq = {
    enable = true;
    settings = {
      battery = {
        governor = "powersave";
        turbo = "never";
      };
      charger = {
        governor = "performance";
        turbo = "auto";
      };
    };
  };

  # CPU power management — kept here, not in system.nix, so other hosts aren't affected
  services.tlp.settings = {
    CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
    CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

    PLATFORM_PROFILE_ON_AC = "performance";
    PLATFORM_PROFILE_ON_BAT = "low-power";

    START_CHARGE_THRESH_BAT0 = 20;
    STOP_CHARGE_THRESH_BAT0 = 80;

    USB_AUTOSUSPEND = lib.mkForce 0; # system.nix sets 1 — HID devices drop with autosuspend
  };

  programs.zsh.shellAliases.keycolor = "msi-perkeyrgb --model GS65 --id 1038:1122 -s";

  systemd.user.services.keyboard-theme = {
    description = "Apply keyboard RGB from active theme";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${msi-perkeyrgb}/bin/msi-perkeyrgb --model GS65 --id 1038:1122 -s ${accentHex}";
    };
  };
}
