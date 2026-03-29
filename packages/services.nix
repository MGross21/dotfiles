{ pkgs, ... }:

{
  # SERVICES
  # Notification Daemon
  services.dunst = {
    enable = true;
    settings = {
      global = {
        monitor = 0;
        geometry = "300x5-30+20";
        transparency = 10;
        padding = 8;
        horizontal_padding = 8;
        text_icon_padding = 0;
        idle_threshold = 120;
        font = "Ubuntu Mono 10";
        line_height = 0;
        markup = "full";
        format = "<b>%s</b>\\n%b";
        alignment = "left";
        vertical_alignment = "center";
        show_age_threshold = 60;
      };
    };
  };

  # NETWORK MANAGER
  services.networkmanager = {
    enable = true;
    appendNameservers = [ "1.1.1.1" "1.0.0.1" ];
  };

  # POWER MANAGEMENT
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      
      # Enable CPU turbo boost on AC, disable on battery
      CPU_TURBO_PSTATE = "auto";
      CPU_TURBO_PSTATE_PREFERRED = "performance";

      BATTERY_CHARGE_THRESHOLDS_ENABLE = false;  # TODO: Enable if supported by your battery
    };
  };

  # THERMAL MANAGEMENT
  services.thermald = {
    enable = true;
  };

  # BLUETOOTH
  hardware.bluetooth.enable = true;
  services.blueman = {
    enable = true;
  };

  # PIPEWIRE AUDIO
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    audio.enable = true;
    pulse.enable = true;
    alsa.enable = true;
    jack.enable = true;
  };

  # TODO: Additional services
  # 
  # UFW Firewall (uncomment if preferred):
  # networking.firewall.enable = true;
  # networking.firewall.allowedTCPPorts = [ ];
  # networking.firewall.allowedUDPPorts = [ ];
  #
  # SSH Server (uncomment if needed):
  # services.openssh = {
  #   enable = true;
  #   ports = [ 22 ];
  #   settings.PasswordAuthentication = false;
  # };
  #
  # VPN (uncomment if needed):
  # services.openvpn.servers = {
  #   # Your VPN configurations here
  # };
}