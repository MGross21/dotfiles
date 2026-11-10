{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.alerts;
  host = config.networking.hostName;
  relayUrl = "http://${cfg.relayHost}.${config.tailnet}:${toString cfg.port}/";

  notify = pkgs.writeShellApplication {
    name = "notify-failure";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      systemd
    ];
    runtimeEnv = {
      ALERT_HOST = host;
      RELAY_URL = relayUrl;
      COOLDOWN = toString cfg.cooldown;
    };
    text = builtins.readFile ./notify-failure.sh;
  };

  relayHandler = pkgs.writeShellApplication {
    name = "alert-relay";
    runtimeInputs = [ pkgs.coreutils ];
    runtimeEnv.RELAY_COMMAND = cfg.relay.command;
    text = builtins.readFile ./relay.sh;
  };
in
{
  options.alerts = {
    units = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Units that send an alert to the relay host when they fail.";
    };
    cooldown = lib.mkOption {
      type = lib.types.ints.unsigned;
      default = 1800;
      description = "Seconds to suppress repeat alerts for the same unit.";
    };
    relayHost = lib.mkOption {
      type = lib.types.str;
      default = "dell";
      description = "Tailnet host that delivers alerts.";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8182;
      readOnly = true;
    };
    relay = {
      enable = lib.mkEnableOption "delivering tailnet alerts with `relay.command`";
      command = lib.mkOption {
        type = lib.types.str;
        description = "Command that delivers the alert text read from stdin.";
      };
      user = lib.mkOption {
        type = lib.types.str;
        description = "User the delivery command runs as.";
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.units != [ ]) {
      systemd.services =
        lib.genAttrs cfg.units (_: {
          onFailure = [ "notify-failure@%n.service" ];
        })
        // {
          "notify-failure@" = {
            description = "Send %i failure alert";
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${lib.getExe notify} %i";
              DynamicUser = true;
              StateDirectory = "notify-failure/%i";
              SupplementaryGroups = [ "systemd-journal" ];
            };
          };
        };
    })

    (lib.mkIf cfg.relay.enable {
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ cfg.port ];

      systemd.sockets.alert-relay = {
        wantedBy = [ "sockets.target" ];
        listenStreams = [ (toString cfg.port) ];
        socketConfig.Accept = true;
      };

      systemd.services."alert-relay@".serviceConfig = {
        ExecStart = lib.getExe relayHandler;
        User = cfg.relay.user;
        StandardInput = "socket";
        StandardOutput = "socket";
        StandardError = "journal";
      };
    })
  ];
}
