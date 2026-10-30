{
  config,
  inputs,
  pkgs,
  ...
}:
let
  modelFile = "Qwen3.6-35B-A3B-UD-IQ4_XS.gguf";
  modelUrl = "https://huggingface.co/unsloth/Qwen3.6-35B-A3B-GGUF/resolve/a483e9e6cbd595906af30beda3187c2663a1118c/${modelFile}";
  modelSha256 = builtins.convertHash {
    hash = "sha256-ZJ11CFB7hGOHMsT1LCTIsVhDxtyi8/95OuB8FKZ+u7M=";
    toHashFormat = "base16";
  };
  model = "/var/lib/llama-cpp/${modelFile}";
  fetchModel = pkgs.writeShellScript "llama-cpp-fetch-model" ''
    set -eu
    [ -e ${model} ] && exit 0
    ${pkgs.curl}/bin/curl -fL --retry 5 -C - -o ${model}.part ${modelUrl}
    if ! echo "${modelSha256}  ${model}.part" | ${pkgs.coreutils}/bin/sha256sum -c -; then
      rm -f ${model}.part
      exit 1
    fi
    mv ${model}.part ${model}
  '';
  contextWindow = 65536;
  llama = config.services.llama-cpp.settings;
  gateway = config.services.openclaw-gateway;
  openclawPkgs = inputs.openclaw.packages.${pkgs.stdenv.hostPlatform.system};
  tokenEnv = "${gateway.stateDir}/gateway.env";
  decisionModel = "gliclass-edge-v3.0";
in
{
  services.llama-cpp = {
    enable = true;
    settings = {
      inherit model;
      jinja = true;
      ctx-size = contextWindow;
      threads = 4;
      cache-reuse = 256;
      flash-attn = "on";
    };
  };

  systemd.services.llama-cpp = {
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      ExecStartPre = [ fetchModel ];
      TimeoutStartSec = "2h";
    };
  };

  services.openclaw-gateway = {
    enable = true;
    package = openclawPkgs.openclaw-gateway;
    environmentFiles = [ "-${tokenEnv}" ];
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
        load.paths = [ "${openclawPkgs.openclaw-runtime-plugin-onnx}" ];
        entries.onnx = {
          enabled = true;
          config = {
            threads = 2;
            maxLoadedModels = 1;
          };
        };
      };
      agents.defaults = {
        model.primary = "local/qwen3.6-35b-a3b";
        decisionModel = "onnx/${decisionModel}";
        experimental.decisionAssistance = true;
      };
      models = {
        mode = "merge";
        providers.local = {
          baseUrl = "http://${llama.host}:${toString llama.port}/v1";
          apiKey = "sk-local";
          api = "openai-completions";
          timeoutSeconds = 900;
          models = [
            {
              id = "qwen3.6-35b-a3b";
              name = "Qwen3.6 35B-A3B";
              reasoning = true;
              input = [ "text" ];
              inherit contextWindow;
              maxTokens = 8192;
            }
          ];
        };
      };
    };
  };

  systemd.services.openclaw-gateway = {
    after = [
      "llama-cpp.service"
      "network-online.target"
    ];
    wants = [
      "llama-cpp.service"
      "network-online.target"
    ];
    serviceConfig = {
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
    };
  };
}
