{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.llm;
  modelFile = "Qwen3.6-35B-A3B-UD-IQ4_XS.gguf";
  modelUrl = "https://huggingface.co/unsloth/Qwen3.6-35B-A3B-GGUF/resolve/a483e9e6cbd595906af30beda3187c2663a1118c/${modelFile}";
  modelSha256 = builtins.convertHash {
    hash = "sha256-ZJ11CFB7hGOHMsT1LCTIsVhDxtyi8/95OuB8FKZ+u7M=";
    toHashFormat = "base16";
  };
  fetchModel = pkgs.writeShellApplication {
    name = "llm-fetch-model";
    runtimeInputs = with pkgs; [
      coreutils
      curl
    ];
    runtimeEnv = {
      MODEL_URL = modelUrl;
      MODEL_SHA256 = modelSha256;
    };
    text = builtins.readFile ./fetch-model.sh;
  };
  fetchModelTo = dir: "${lib.getExe fetchModel} ${dir}/${modelFile}";

  package = pkgs.llama-cpp.override {
    cudaSupport = cfg.cuda;
    vulkanSupport = cfg.vulkan;
  };
  serverSettings =
    dir:
    {
      model = "${dir}/${modelFile}";
      jinja = true;
      ctx-size = cfg.model.contextWindow;
      cache-reuse = 256;
      flash-attn = "on";
      parallel = 1;
      metrics = true;
    }
    // lib.optionalAttrs cfg.cpuExperts {
      n-gpu-layers = 99;
      n-cpu-moe = 99;
      no-op-offload = true;
    };

  systemctl = "${pkgs.systemd}/bin/systemctl";
  lendUnit = "llama-swap.service";
  idleTicksBeforeSuspend = 30;

  guard = pkgs.writeShellApplication {
    name = "llm-guard";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      gawk
      gnugrep
      jq
      systemd
    ];
    runtimeEnv = {
      LLM_PORT = cfg.port;
      IDLE_TICKS = idleTicksBeforeSuspend;
    };
    text = builtins.readFile ./guard.sh;
  };

  wakeSocket = "/run/llm-wake.sock";
  borrowMac = config.hosts.${cfg.borrowFrom}.mac or null;
  wake = pkgs.writeShellScriptBin "wake-${toString cfg.borrowFrom}" ''
    exec ${lib.getExe pkgs.wakeonlan} ${toString borrowMac} >/dev/null
  '';
  wakeResponder = pkgs.writeShellScript "llm-wake-respond" ''
    while IFS= read -r line && [ -n "''${line%$'\r'}" ]; do :; done
    ${lib.getExe wake}
    printf 'HTTP/1.1 503 Service Unavailable\r\nContent-Length: 0\r\nConnection: close\r\n\r\n'
  '';
in
{
  options.llm = {
    enable = lib.mkEnableOption "an always-on llama.cpp server for the shared local model";
    cuda = lib.mkEnableOption "CUDA offload";
    vulkan = lib.mkEnableOption "Vulkan offload";
    cpuExperts = lib.mkEnableOption "keeping MoE expert weights on the CPU and every other layer on the GPU";
    lend = lib.mkEnableOption "lending the GPU to tailnet peers on demand while the desktop user is idle";
    borrowFrom = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Tailnet host whose lent model is pooled with the local server on `proxyPort`; each request also sends it Wake-on-LAN.";
    };
    borrowAddress = lib.mkOption {
      type = lib.types.str;
      default = "${toString cfg.borrowFrom}.${config.tailnet}";
      description = "Address of the `borrowFrom` host.";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 8180;
      readOnly = true;
      description = "Port of the llama.cpp server.";
    };
    proxyPort = lib.mkOption {
      type = lib.types.port;
      default = 8181;
      readOnly = true;
      description = "Port of the proxy that pools the local server with `borrowFrom`.";
    };
    model = lib.mkOption {
      type = lib.types.attrs;
      readOnly = true;
      description = "Identifier, display name and context window of the served model.";
      default = {
        id = "qwen3.6-35b-a3b";
        name = "Qwen3.6 35B-A3B";
        contextWindow = 65536;
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.vulkan {
      hardware.graphics.enable = true;
    })

    (lib.mkIf cfg.enable {
      alerts.units = [ "llama-cpp" ];

      services.llama-cpp = {
        enable = true;
        inherit package;
        settings = serverSettings "/var/lib/llama-cpp" // {
          inherit (cfg) port;
        };
      };

      systemd.services.llama-cpp = {
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        environment.MESA_SHADER_CACHE_DIR = "/var/cache/llama-cpp";
        serviceConfig = {
          ExecStartPre = [ (fetchModelTo "/var/lib/llama-cpp") ];
          TimeoutStartSec = "2h";
        };
      };
    })

    (lib.mkIf cfg.lend {
      alerts.units = [ "llama-swap" ];

      services.llama-swap = {
        enable = true;
        listenAddress = "0.0.0.0";
        inherit (cfg) port;
        settings = {
          healthCheckTimeout = 600;
          models.${cfg.model.id} = {
            cmd = "${lib.getExe' package "llama-server"} --port \${PORT} --no-webui ${
              lib.cli.toCommandLineShell (name: {
                option = "--${name}";
                sep = null;
                explicitBool = false;
              }) (serverSettings "/var/lib/llm")
            }";
            ttl = 900;
          };
        };
      };

      systemd.services.llama-swap = {
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig = {
          StateDirectory = "llm";
          ExecStartPre = [ (fetchModelTo "/var/lib/llm") ];
          TimeoutStartSec = "2h";
        };
      };

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ cfg.port ];

      systemd.services.llm-guard = {
        description = "Hold off sleep while a lent model is loaded; suspend once unused";
        bindsTo = [ lendUnit ];
        after = [ lendUnit ];
        wantedBy = [ lendUnit ];
        serviceConfig.ExecStart = lib.getExe guard;
      };

      security.polkit.extraConfig = ''
        polkit.addRule(function (action, subject) {
          if (action.id == "org.freedesktop.systemd1.manage-units" &&
              action.lookup("unit") == "${lendUnit}" &&
              (action.lookup("verb") == "start" || action.lookup("verb") == "stop") &&
              subject.user == "${config.user.name}") {
            return polkit.Result.YES;
          }
        });
      '';

      systemd.user.services.llm-yield = {
        description = "Withhold the GPU from tailnet peers during the desktop session";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${systemctl} --no-block stop ${lendUnit}";
          ExecStop = "${systemctl} --no-block start ${lendUnit}";
        };
      };

      desktop.idle.listeners = [
        {
          timeout = 300;
          on-timeout = "${systemctl} --no-block start ${lendUnit}";
          on-resume = "${systemctl} --no-block stop ${lendUnit}";
        }
      ];
    })

    (lib.mkIf (cfg.borrowFrom != null) {
      assertions = [
        {
          assertion = cfg.enable;
          message = "llm.borrowFrom pools with the local server; enable llm.enable too.";
        }
        {
          assertion = borrowMac != null;
          message = "llm.borrowFrom needs hosts.${cfg.borrowFrom}.mac for Wake-on-LAN.";
        }
      ];

      environment.systemPackages = [ wake ];
      alerts.units = [ "nginx" ];

      services.nginx = {
        enable = true;
        resolver.addresses = [ "100.100.100.100" ];
        upstreams.llm-pool = {
          servers = {
            "${cfg.borrowAddress}:${toString cfg.port}" = {
              resolve = true;
              max_conns = 1;
              max_fails = 1;
              fail_timeout = "30s";
            };
            "127.0.0.1:${toString cfg.port}".backup = true;
          };
          extraConfig = "zone llm-pool 64k;";
        };
        virtualHosts.llm-pool = {
          listen = [
            {
              addr = "127.0.0.1";
              port = cfg.proxyPort;
            }
          ];
          locations."/" = {
            proxyPass = "http://llm-pool";
            extraConfig = ''
              mirror /wake;
              mirror_request_body off;
              proxy_http_version 1.1;
              proxy_connect_timeout 3s;
              proxy_read_timeout 900s;
              proxy_send_timeout 900s;
              proxy_buffering off;
              proxy_next_upstream error timeout http_500 http_502 http_503 non_idempotent;
            '';
          };
          locations."= /wake" = {
            proxyPass = "http://unix:${wakeSocket}:";
            extraConfig = ''
              internal;
              proxy_pass_request_body off;
              proxy_set_header Content-Length "";
            '';
          };
        };
      };

      systemd.sockets.llm-wake = {
        wantedBy = [ "sockets.target" ];
        listenStreams = [ wakeSocket ];
        socketConfig = {
          Accept = true;
          SocketUser = config.services.nginx.user;
          SocketMode = "0600";
        };
      };

      systemd.services."llm-wake@".serviceConfig = {
        ExecStart = wakeResponder;
        StandardInput = "socket";
        StandardOutput = "socket";
        DynamicUser = true;
      };
    })
  ];
}
