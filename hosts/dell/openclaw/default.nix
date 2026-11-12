{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  gateway = config.services.openclaw-gateway;
  openclawPkgs = inputs.openclaw.packages.${pkgs.stdenv.hostPlatform.system};
  tokenEnv = "${gateway.stateDir}/gateway.env";
  discordEnv = "${gateway.stateDir}/discord.env";
  decisionModel = "gliclass-edge-v3.0";
  owner = "291420737204649985";
  model = config.llm.model // {
    reasoning = true;
    input = [ "text" ];
    maxTokens = 8192;
  };
  alertDm = pkgs.writeShellApplication {
    name = "alert-dm";
    runtimeInputs = with pkgs; [
      curl
      jq
    ];
    runtimeEnv = {
      DISCORD_ENV = discordEnv;
      OWNER = owner;
    };
    text = builtins.readFile ./alert-dm.sh;
  };
  openclawAdmin = pkgs.writeShellApplication {
    name = "openclaw-admin";
    runtimeInputs = [
      gateway.package
      pkgs.coreutils
    ];
    runtimeEnv = {
      OPENCLAW_USER = gateway.user;
      TOKEN_ENV = tokenEnv;
      DISCORD_ENV = discordEnv;
      OPENCLAW_STATE_DIR = gateway.stateDir;
      OPENCLAW_CONFIG_PATH = gateway.configPath;
    };
    text = builtins.readFile ./admin.sh;
  };
in
{
  environment.systemPackages = [ openclawAdmin ];
  alerts = {
    units = [ "openclaw-gateway" ];
    relay = {
      enable = true;
      command = lib.getExe alertDm;
      inherit (gateway) user;
    };
  };

  llm = {
    enable = true;
    borrowFrom = "pc";
    vulkan = true;
    cpuExperts = true;
  };
  services.llama-cpp.settings.threads = 4;

  services.openclaw-gateway = {
    enable = true;
    package = openclawPkgs.openclaw-gateway;
    environmentFiles = [
      "-${tokenEnv}"
      "-${discordEnv}"
    ];
    execStartPre = [
      (toString (
        pkgs.writeShellScript "openclaw-gateway-token" ''
          [ -s ${tokenEnv} ] || echo "OPENCLAW_GATEWAY_TOKEN=$(${pkgs.openssl}/bin/openssl rand -hex 32)" > ${tokenEnv}
        ''
      ))
      (toString (
        pkgs.writeShellScript "openclaw-onnx-model" ''
          [ -d ${gateway.stateDir}/models/onnx/${decisionModel} ] || ${gateway.package}/bin/openclaw onnx download ${decisionModel}
        ''
      ))
    ];
    config = {
      gateway = {
        mode = "local";
        bind = "loopback";
        auth = {
          mode = "token";
          token = {
            source = "env";
            provider = "default";
            id = "OPENCLAW_GATEWAY_TOKEN";
          };
        };
      };
      plugins = {
        load.paths = [
          "${openclawPkgs.openclaw-runtime-plugin-onnx}"
          "${openclawPkgs.openclaw-runtime-plugin-discord}"
        ];
        deny = [
          "acpx"
          "anthropic"
          "browser"
          "canvas"
          "cua-computer"
          "file-transfer"
          "geolocation"
          "github"
          "ollama"
          "talk-voice"
          "xai"
        ];
        entries.discord.enabled = true;
        entries.onnx = {
          enabled = true;
          config = {
            threads = 2;
            maxLoadedModels = 1;
          };
        };
      };
      channels.discord = {
        enabled = true;
        token = {
          source = "env";
          provider = "default";
          id = "DISCORD_BOT_TOKEN";
        };
        dmPolicy = "allowlist";
        allowFrom = [ owner ];
        groupPolicy = "allowlist";
        voice.enabled = false;
        execApprovals = {
          enabled = true;
          approvers = [ owner ];
          target = "dm";
          cleanupAfterResolve = true;
        };
      };
      commands.ownerAllowFrom = [ "discord:${owner}" ];
      tools = {
        deny = [ "github_publish" ];
        exec = {
          mode = "ask";
          host = "gateway";
          strictInlineEval = true;
        };
        elevated.enabled = false;
        fs.workspaceOnly = true;
      };
      agents.defaults = {
        model.primary = "pool/${model.id}";
        decisionModel = "onnx/${decisionModel}";
        experimental.decisionAssistance = true;
        timeoutSeconds = 0;
      };
      models = {
        mode = "merge";
        providers.pool = {
          baseUrl = "http://127.0.0.1:${toString config.llm.proxyPort}/v1";
          apiKey = "sk-local";
          api = "openai-completions";
          timeoutSeconds = 900;
          models = [ model ];
        };
      };
    };
  };

  systemd.services.openclaw-gateway = {
    restartTriggers = [ config.environment.etc."openclaw/openclaw.json".source ];
    after = [
      "llama-cpp.service"
      "nginx.service"
      "network-online.target"
    ];
    wants = [
      "llama-cpp.service"
      "nginx.service"
      "network-online.target"
    ];
    serviceConfig = {
      RestartPreventExitStatus = 78;
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
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
      UMask = "0077";
      CapabilityBoundingSet = "";
      AmbientCapabilities = "";
      ReadWritePaths = [ "/var/lib/openclaw" ];
      RestrictAddressFamilies = [
        "AF_UNIX"
        "AF_INET"
        "AF_INET6"
      ];
      IPAddressAllow = [
        "localhost"
        "100.100.100.100"
        "fd7a:115c:a1e0::53"
      ];
      IPAddressDeny = [
        "0.0.0.0/8"
        "10.0.0.0/8"
        "100.64.0.0/10"
        "169.254.0.0/16"
        "172.16.0.0/12"
        "192.168.0.0/16"
        "224.0.0.0/4"
        "fc00::/7"
        "fe80::/10"
        "ff00::/8"
      ];
    };
  };

  environment.etc."openclaw/openclaw.json" = {
    mode = lib.mkForce "0400";
    inherit (gateway) user group;
  };

  systemd.tmpfiles.settings."00-0-${config.networking.hostName}-openclaw".${gateway.stateDir}.d = {
    mode = "0700";
    inherit (gateway) user group;
  };
}
