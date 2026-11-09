{
  config,
  pkgs,
  lib,
  ...
}:
let
  accentHex = lib.removePrefix "#" config.theming.accent;
  modprobe = lib.getExe' pkgs.kmod "modprobe";
  powerSourceSwitch = lib.getExe (
    pkgs.writeShellApplication {
      name = "power-source-switch";
      runtimeInputs = [
        pkgs.coreutils
        pkgs.hyprland
      ];
      text = builtins.readFile ./power-source-switch.sh;
    }
  );
in
{
  imports = [
    ./hardware-configuration.nix
    ./audio.nix
  ];

  networking.hostName = "msi";
  theming.name = "osaka-jade";

  desktop = {
    enable = true;
    environment = "hyprland";
    deskflow.enable = true;
    airdrop.enable = true;
  };

  dev = {
    rust.enable = true;
    python.enable = true;
    js.enable = true;
    jvm.enable = false;
    android.enable = false;
    apple.enable = true;
  };

  apps = {
    enable = true;
    creative.enable = false;
    media.enable = true;
    gaming.enable = true;
  };

  boot.initrd.kernelModules = [ "i915" ]; # early KMS for plymouth
  boot.kernelModules = [ "ec_sys" ]; # required by MControlCenter for EC access

  boot.kernelParams = [
    "mem_sleep_default=deep"
    "nologo"
    "pcie_aspm=force" # BIOS withholds ASPM control; TLP's PCIE_ASPM_* are no-ops without it
    "i915.enable_psr=2"
    "i915.enable_fbc=1"
    "i915.enable_guc=2"
    "nmi_watchdog=0"
    "nowatchdog"
    "preempt=full"
    "mitigations=off" # single-user trusted machine
    "quiet"
    "udev.log_level=3"
    "rd.udev.log_level=3"
    "rd.systemd.show_status=false"
    "systemd.show_status=false"
    "vt.global_cursor_default=0"
    "plymouth.ignore-serial-consoles"
    # PID 1 otherwise waits 333ms per stage on a size query the VT never answers.
    "systemd.tty.rows.console=67"
    "systemd.tty.columns.console=240"
  ];

  # i7-9750H is CPUID 06-9e-0a; no LUKS/LVM/TPM unlock on this disk.
  hardware.cpu.intel.microcodePackage = pkgs.microcode-intel.overrideAttrs {
    postPatch = "find intel-ucode -type f ! -name 06-9e-0a -delete";
  };
  boot.initrd.systemd.tpm2.enable = false;
  boot.initrd.services.lvm.enable = false;

  boot.extraModprobeConfig = ''
    options iwlwifi power_save=0
    options iwlmvm power_scheme=1
    options ec_sys write_support=1
  '';

  # GTX 1660 Ti Mobile (TU116M) + Intel UHD 630
  gpu.nvidia.enable = true;
  hardware.graphics.extraPackages = [ pkgs.intel-media-driver ];
  boot.blacklistedKernelModules = [ "psmouse" ];

  hardware.nvidia = {
    powerManagement.enable = true;
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };
  # The nvidia module force-loads nvidia_uvm via modules-load, which blocks sysinit.
  environment.etc."modules-load.d/nixos.conf".source = lib.mkForce (
    pkgs.writeText "nixos.conf" (lib.concatLines (lib.remove "nvidia_uvm" config.boot.kernelModules))
  );
  systemd.services.nvidia-modules = lib.mkIf config.hardware.nvidia.enabled {
    description = "Load NVIDIA DRM and UVM modules";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "exec";
      RemainAfterExit = true;
      ExecStart = "${modprobe} -a nvidia_drm nvidia_uvm";
    };
  };

  specialisation.battery.configuration = {
    system.nixos.tags = [ "battery" ];
    services.xserver.videoDrivers = lib.mkForce [ "modesetting" ];
    environment.sessionVariables.AQ_DRM_DEVICES = lib.mkForce "/dev/dri/igpu";
  };

  # Colon-separated list, so the path must be colon-free — /dev/dri/by-path names split.
  environment.sessionVariables.AQ_DRM_DEVICES = "/dev/dri/igpu:/dev/dri/dgpu";
  environment.sessionVariables.LIBVA_DRIVER_NAME = "iHD";
  # RT main thread gets SIGKILLed by RLIMIT_RTTIME on any >200ms stall.
  environment.sessionVariables.HYPRLAND_NO_RT = "1";
  # Mesa-only EGL keeps hyprpaper on the iGPU.
  systemd.user.services.hyprpaper.environment.__EGL_VENDOR_LIBRARY_FILENAMES =
    "${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json";
  programs.firefox.preferences = {
    "media.ffmpeg.vaapi.enabled" = true;
    "media.av1.enabled" = false;
  };
  environment.systemPackages = with pkgs; [
    libva
    libva-vdpau-driver
    libvdpau-va-gl
    msi-perkeyrgb
    mcontrolcenter
  ];

  systemd.services.power-source-switch = {
    description = "Apply panel refresh rate and CPU package limit for the current power source";
    wantedBy = [
      "multi-user.target"
      "post-resume.target"
    ];
    after = [ "post-resume.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = powerSourceSwitch;
    };
  };

  systemd.user.services.panel-refresh = {
    description = "Apply panel refresh rate for the current power source";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = powerSourceSwitch;
    };
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:00:02.0", SYMLINK+="dri/igpu"
    SUBSYSTEM=="drm", KERNEL=="card*", KERNELS=="0000:01:00.0", SYMLINK+="dri/dgpu"
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x2725", ATTR{d3cold_allowed}="0"
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1038", ATTRS{idProduct}=="1122", MODE="0666"
    SUBSYSTEM=="power_supply", KERNEL=="ADP1", TAG+="systemd", ENV{SYSTEMD_WANTS}+="power-source-switch.service"
  ''
  # `battery` removes the dGPU from the bus; HDMI and USB-C DP are wired to it, so external displays need the default config.
  + lib.optionalString (!config.hardware.nvidia.enabled) ''
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{power/control}="auto", ATTR{remove}="1"
  '';

  # AX210 (0x2725) enters D3cold on suspend and hard-crashes.
  systemd.services.ax210-suspend = {
    description = "Unload AX210 WiFi driver before suspend, reload after resume";
    before = [ "sleep.target" ];
    wantedBy = [ "sleep.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "ax210-pre-suspend" ''
        echo 0 > /sys/bus/pci/devices/0000:3d:00.0/d3cold_allowed
        ${modprobe} -r iwlmvm || true
        ${modprobe} -r iwlwifi || true
      '';
      ExecStop = pkgs.writeShellScript "ax210-post-resume" ''
        ${modprobe} iwlwifi
        sleep 2
        ${modprobe} iwlmvm
        ${lib.getExe' pkgs.util-linux "rfkill"} unblock wifi
      '';
    };
  };

  services.displayManager.ly.settings.battery_id = "BAT1";
  services.thermald.enable = true;

  # Defaulted on by the nvidia module; logind handles lid/power keys.
  services.acpid.enable = false;

  services.scx-loader = {
    enable = true;
    config = {
      default_sched = "scx_lavd";
      default_mode = "Auto";
      scheds.scx_lavd.auto_mode = [ "--autopower" ]; # follows TLP's EPP per power source
    };
  };

  # coreOffset also sets cache; p1/p2 stay unset because power-source-switch owns RAPL.
  services.undervolt = {
    enable = true;
    coreOffset = -80;
    temp = 90;
  };

  nix.settings = {
    max-jobs = 4;
    cores = 3;
  };

  # Weights bite only under contention; an idle session still gets full speed.
  systemd.services.nix-daemon.serviceConfig = {
    CPUWeight = 20;
    IOWeight = 20;
    MemoryHigh = "8G";
  };

  # Outranks the disk swap in hardware-configuration.nix, which stays as overflow.
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # Sole owner of governor/EPP/boost; conflicts with auto-cpufreq.
  services.tlp.settings = {
    CPU_SCALING_GOVERNOR_ON_AC = "powersave";
    CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
    CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
    CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
    CPU_BOOST_ON_AC = 1;
    CPU_BOOST_ON_BAT = 0;
    CPU_HWP_DYN_BOOST_ON_AC = 1;
    CPU_HWP_DYN_BOOST_ON_BAT = 0;

    START_CHARGE_THRESH_BAT1 = 20;
    STOP_CHARGE_THRESH_BAT1 = 80;

    USB_DENYLIST = "1038:1122"; # SteelSeries per-key keyboard drops out on autosuspend

    # Must be explicit on both: TLP defaults to 1, which puts the codec in D3 and kills mic capture.
    SOUND_POWER_SAVE_ON_AC = 0;
    SOUND_POWER_SAVE_ON_BAT = lib.mkForce 0;
    SOUND_POWER_SAVE_CONTROLLER = lib.mkForce "N";
  };

  home-manager.sharedModules = [
    { home.shellAliases.keycolor = "msi-perkeyrgb --model GS65 --id 1038:1122 -s"; }
  ];

  systemd.user.services.keyboard-theme = {
    description = "Apply keyboard RGB from active theme";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${lib.getExe' pkgs.msi-perkeyrgb "msi-perkeyrgb"} --model GS65 --id 1038:1122 -s ${accentHex}";
    };
  };
}
