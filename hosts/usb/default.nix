{ config, lib, ... }:
let
  inherit (config.user) name;
in
{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "nixos";
  theming.name = "tokyo-night";

  desktop.enable = true;
  apps.enable = true;

  storage.disko = {
    enable = true;
    ephemeral = true;
    encrypt = true;
    device = "/dev/disk/by-id/PLACEHOLDER";
  };

  boot.loader = {
    timeout = lib.mkForce 3;
    systemd-boot.configurationLimit = lib.mkForce 3;
    efi.canTouchEfiVariables = lib.mkForce false;
  };

  zramSwap.enable = true;

  users.mutableUsers = false;
  users.users.${name} = {
    initialPassword = lib.mkForce null;
    hashedPasswordFile = "/persist/passwords/${name}";
  };

  services.openssh.enable = lib.mkForce false;
  services.tailscale.enable = lib.mkForce false;

  networking.firewall = {
    allowedTCPPorts = lib.mkForce [ ];
    allowedUDPPorts = lib.mkForce [ ];
    allowPing = false;
  };

  networking.networkmanager = {
    wifi = {
      macAddress = "random";
      scanRandMacAddress = lib.mkForce true;
    };
    ethernet.macAddress = "random";
    settings.connection = {
      "ipv4.dhcp-send-hostname" = false;
      "ipv6.dhcp-send-hostname" = false;
      "ipv4.dhcp-client-id" = "mac";
      "ipv6.dhcp-duid" = "ll";
      "ipv6.ip6-privacy" = 2;
    };
  };

  preservation = {
    enable = true;
    preserveAt."/persist".directories = [
      {
        directory = "/var/lib/nixos";
        inInitrd = true;
      }
      {
        directory = "/var/lib/bluetooth";
        mode = "0700";
      }
      {
        directory = "/etc/NetworkManager/system-connections";
        mode = "0700";
      }
    ];
  };

  home-manager.users.${name}.dotfiles.mutable = false;

  specialisation.nvidia.configuration = {
    hardware.nvidia = {
      open = true;
      modesetting.enable = true;
      nvidiaSettings = false;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
    services.xserver.videoDrivers = [ "nvidia" ];
  };
}
