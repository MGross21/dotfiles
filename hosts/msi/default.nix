{
  config,
  pkgs,
  lib,
  ...
}:
let
  accentHex = lib.removePrefix "#" config.theming.colors.blue;
  # `hyprctl keyword` is rejected under the Lua parser, hence eval + hl.monitor().
  powerSourceSwitch = pkgs.writeShellScript "power-source-switch" ''
    set -u
    if [ "$(cat /sys/class/power_supply/ADP1/online 2>/dev/null || echo 1)" = "1" ]; then
      mode=144.03
      pl1=55000000
    else
      mode=60.08
      pl1=25000000
    fi

    limit=/sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw
    [ -w "$limit" ] && echo "$pl1" > "$limit"

    for dir in /run/user/*/hypr/*/; do
      [ -d "$dir" ] || continue
      uid=$(echo "$dir" | cut -d/ -f4)
      sig=$(basename "$dir")
      HYPRLAND_INSTANCE_SIGNATURE="$sig" XDG_RUNTIME_DIR="/run/user/$uid" \
        ${pkgs.hyprland}/bin/hyprctl eval \
          "hl.monitor({output='eDP-1',mode='1920x1080@$mode',position='0x0',scale=1.0})" || true
    done
  '';
in
{
  imports = [
    ./hardware-configuration.nix
    ./audio.nix
  ];

  networking.hostName = "msi";
  theming.name = "tomorrow-night-burns";

  desktop = {
    enable = true;
    environment = "hyprland";
  };

  dev = {
    rust.enable = true;
    python.enable = true;
    js.enable = true;
    jvm.enable = false;
    android.enable = false;
  };

  apps = {
    enable = true;
    creative.enable = false;
    media.enable = true;
    gaming.enable = true;
  };

  boot.initrd.kernelModules = [ "i915" ]; # early KMS for plymouth
  boot.kernelModules = lib.mkBefore [
    "nvidia-drm"
    "ec_sys" # required by MControlCenter for EC access
  ];
  boot.kernelParams = [
    "mem_sleep_default=deep"
    "nologo"
    "pcie_aspm=force" # BIOS withholds ASPM control; TLP's PCIE_ASPM_* are no-ops without it
    "i915.enable_psr=2"
    "i915.enable_fbc=1"
    "nmi_watchdog=0"
    "mitigations=off" # single-user trusted machine
    "quiet"
    "udev.log_level=3"
    "rd.udev.log_level=3"
    "rd.systemd.show_status=false"
    "systemd.show_status=false"
    "vt.global_cursor_default=0"
    "plymouth.ignore-serial-consoles"
  ];

  boot.extraModprobeConfig = ''
    options iwlwifi power_save=0
    options iwlmvm power_scheme=1
    options ec_sys write_support=1
    options nvidia NVreg_DynamicPowerManagement=0x02
  '';

  # GTX 1660 Ti Mobile (TU116M) + Intel UHD 630
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

  # Colon-separated list, so the path must be colon-free — /dev/dri/by-path names split.
  environment.sessionVariables.AQ_DRM_DEVICES = "/dev/dri/igpu";
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
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x2725", ATTR{d3cold_allowed}="0"
    KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1038", ATTRS{idProduct}=="1122", MODE="0666"
    SUBSYSTEM=="power_supply", KERNEL=="ADP1", TAG+="systemd", ENV{SYSTEMD_WANTS}+="power-source-switch.service"
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

  # auto-cpufreq owns the governor; TLP owns energy policy and boost.
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

  services.tlp.settings = {
    CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
    CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

    START_CHARGE_THRESH_BAT1 = 20;
    STOP_CHARGE_THRESH_BAT1 = 80;

    USB_DENYLIST = "1038:1122"; # SteelSeries per-key keyboard drops out on autosuspend

    # Must be explicit on both: TLP defaults to 1, which puts the codec in D3 and kills mic capture.
    SOUND_POWER_SAVE_ON_AC = 0;
    SOUND_POWER_SAVE_ON_BAT = lib.mkForce 0;
    SOUND_POWER_SAVE_CONTROLLER = lib.mkForce "N";
  };

  programs.zsh.shellAliases.keycolor = "msi-perkeyrgb --model GS65 --id 1038:1122 -s";

  systemd.user.services.keyboard-theme = {
    description = "Apply keyboard RGB from active theme";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.msi-perkeyrgb}/bin/msi-perkeyrgb --model GS65 --id 1038:1122 -s ${accentHex}";
    };
  };
}
