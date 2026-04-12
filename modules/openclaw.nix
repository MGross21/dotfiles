{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.openclaw;
  hasGateway = builtins.hasAttr "openclaw-gateway" pkgs;
  defaultGatewayPackage =
    if hasGateway then
      builtins.getAttr "openclaw-gateway" pkgs
    else
      pkgs.writeShellScriptBin "openclaw-gateway" ''
        echo "openclaw-gateway package is not available in this nixpkgs set."
        echo "Use github:openclaw/nix-openclaw in Home Manager or provide services.openclaw.package manually."
        exit 1
      '';

  filterNullAttrs = attrs: lib.filterAttrs (_: value: value != null) attrs;

  featureConfig =
    lib.recursiveUpdate
      (lib.optionalAttrs cfg.features.telegram.enable {
        channels.telegram = filterNullAttrs {
          tokenFile = cfg.features.telegram.tokenFile;
          allowFrom = cfg.features.telegram.allowFrom;
          groups = cfg.features.telegram.groups;
        };
      })
      (
        lib.optionalAttrs cfg.features.discord.enable {
          channels.discord = filterNullAttrs {
            tokenFile = cfg.features.discord.tokenFile;
            allowFrom = cfg.features.discord.allowFrom;
            groups = cfg.features.discord.groups;
          };
        }
      );

  mergedConfig = lib.recursiveUpdate cfg.config featureConfig;
  configJson = builtins.toJSON mergedConfig;
  etcRelPath = lib.removePrefix "/etc/" cfg.configPath;
in
{
  options.services.openclaw = {
    enable = lib.mkEnableOption "OpenClaw gateway service";

    config = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      description = "OpenClaw JSON config written to configPath.";
    };

    configPath = lib.mkOption {
      type = lib.types.str;
      default = "/etc/openclaw/openclaw.json";
      description = "Path to the rendered OpenClaw JSON config.";
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = defaultGatewayPackage;
      description = "Package that provides the openclaw-gateway executable.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "openclaw";
      description = "System user account used to run the OpenClaw service.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "openclaw";
      description = "System group used to run the OpenClaw service.";
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/openclaw";
      description = "Directory for persistent OpenClaw runtime state.";
    };

    environmentFiles = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      example = [ "/run/secrets/openclaw.env" ];
      description = "Environment files passed to the OpenClaw service.";
    };

    extraEnvironment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        OPENCLAW_GATEWAY_TOKEN = "change-me";
      };
      description = "Extra environment variables for the OpenClaw service.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "gateway" ];
      description = "Additional arguments passed to openclaw-gateway.";
    };

    features = {
      telegram = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Telegram transport config.";
        };

        tokenFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Path to the Telegram bot token file.";
        };

        allowFrom = lib.mkOption {
          type = lib.types.listOf lib.types.int;
          default = [ ];
          description = "Telegram user IDs allowed to talk to OpenClaw.";
        };

        groups = lib.mkOption {
          type = lib.types.attrs;
          default = { };
          description = "Optional Telegram group policy map.";
        };
      };

      discord = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Enable Discord transport config.";
        };

        tokenFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Path to the Discord bot token file.";
        };

        allowFrom = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "Discord user or channel IDs allowed to talk to OpenClaw.";
        };

        groups = lib.mkOption {
          type = lib.types.attrs;
          default = { };
          description = "Optional Discord server or channel policy map.";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    users.groups = {
      ${cfg.group} = { };
    };

    users.users = {
      ${cfg.user} = {
        isSystemUser = true;
        group = cfg.group;
        description = "OpenClaw service account";
        home = cfg.stateDir;
        createHome = true;
        shell = pkgs.bashInteractive;
        extraGroups = [ ];
      };
    };

    assertions = [
      {
        assertion = cfg.stateDir != "/";
        message = "services.openclaw.stateDir must not be /.";
      }
      {
        assertion = !cfg.features.telegram.enable || cfg.features.telegram.tokenFile != null;
        message = "services.openclaw.features.telegram.tokenFile must be set when Telegram is enabled.";
      }
      {
        assertion = !cfg.features.discord.enable || cfg.features.discord.tokenFile != null;
        message = "services.openclaw.features.discord.tokenFile must be set when Discord is enabled.";
      }
    ];

    environment.etc.${etcRelPath} = {
      mode = "0640";
      user = "root";
      group = cfg.group;
      text = configJson;
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0750 ${cfg.user} ${cfg.group} -"
    ];

    systemd.services.openclaw-gateway = {
      description = "OpenClaw Gateway";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = cfg.stateDir;
        ExecStart = lib.escapeShellArgs ([ (lib.getExe cfg.package) ] ++ cfg.extraArgs);
        Restart = "on-failure";
        RestartSec = "5s";

        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateDevices = true;
        PrivateMounts = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        UMask = "0077";
        CapabilityBoundingSet = "";
        AmbientCapabilities = "";
        ReadWritePaths = [ cfg.stateDir ];
        ReadOnlyPaths = [ "/run/secrets" ];
        RestrictAddressFamilies = [
          "AF_UNIX"
          "AF_INET"
          "AF_INET6"
        ];
      };

      environment = cfg.extraEnvironment // {
        OPENCLAW_CONFIG_PATH = cfg.configPath;
        OPENCLAW_STATE_DIR = cfg.stateDir;
      };
      environmentFiles = cfg.environmentFiles;
    };
  };
}
