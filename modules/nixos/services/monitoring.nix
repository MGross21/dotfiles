{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.monitoring;
  gpu = config.hosts.${config.networking.hostName}.gpuMetrics or false;
  exporters = config.services.prometheus.exporters;
  grafana = config.services.grafana.settings.server;
  grafanaDir = config.services.grafana.dataDir;

  dashboards = pkgs.linkFarm "grafana-dashboards" [
    {
      name = "node.json";
      path = pkgs.fetchurl {
        url = "https://grafana.com/api/dashboards/1860/revisions/46/download";
        hash = "sha256-5Y3cXcU11MkB+U2pZIvD49Wue2946Y4YW86LKJlhzqM=";
      };
    }
    {
      name = "nvidia-gpu.json";
      path = pkgs.fetchurl {
        url = "https://grafana.com/api/dashboards/14574/revisions/18/download";
        hash = "sha256-tuvm63s/svcc15DikhT94M5exnscMfQCehbqOBX7GGk=";
      };
    }
  ];

  scrape = job: port: names: {
    job_name = job;
    static_configs = map (name: {
      targets = [ "${name}.${config.tailnet}:${toString port}" ];
      labels.instance = name;
    }) names;
  };

  grafanaSecrets = pkgs.writeShellScript "grafana-secrets" ''
    umask 077
    for f in secret_key admin_password; do
      [ -s ${grafanaDir}/$f ] || ${lib.getExe pkgs.openssl} rand -hex 32 > ${grafanaDir}/$f
    done
  '';
in
{
  options.monitoring = {
    server.enable = lib.mkEnableOption "Prometheus and Grafana for every host in `hosts`";
  };

  config = lib.mkMerge [
    {
      services.prometheus.exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" ];
        };
        nvidia-gpu.enable = gpu;
      };

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
        exporters.node.port
      ]
      ++ lib.optional gpu exporters.nvidia-gpu.port;
    }

    (lib.mkIf cfg.server.enable {
      services.prometheus = {
        enable = true;
        listenAddress = "127.0.0.1";
        retentionTime = "90d";
        globalConfig.scrape_interval = "30s";
        scrapeConfigs = [
          (scrape "node" exporters.node.port (lib.attrNames config.hosts))
          (scrape "nvidia-gpu" exporters.nvidia-gpu.port (
            lib.attrNames (lib.filterAttrs (_: h: h.gpuMetrics) config.hosts)
          ))
        ]
        ++ lib.optional config.llm.enable {
          job_name = "llama-cpp";
          static_configs = [
            {
              targets = [ "127.0.0.1:${toString config.llm.port}" ];
              labels.instance = config.networking.hostName;
            }
          ];
        };
      };

      services.grafana = {
        enable = true;
        settings = {
          server = {
            http_addr = "0.0.0.0";
            http_port = 3000;
            domain = "${config.networking.hostName}.${config.tailnet}";
          };
          security = {
            secret_key = "$__file{${grafanaDir}/secret_key}";
            admin_password = "$__file{${grafanaDir}/admin_password}";
          };
          "auth.anonymous" = {
            enabled = true;
            org_role = "Viewer";
          };
          analytics = {
            reporting_enabled = false;
            check_for_updates = false;
          };
        };
        provision = {
          enable = true;
          datasources.settings.datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              url = "http://127.0.0.1:${toString config.services.prometheus.port}";
              isDefault = true;
            }
          ];
          dashboards.settings.providers = [
            {
              name = "default";
              options.path = dashboards;
            }
          ];
        };
      };

      systemd.services.grafana.serviceConfig.ExecStartPre = lib.mkBefore [ grafanaSecrets ];

      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ grafana.http_port ];

      alerts.units = [
        "prometheus"
        "grafana"
      ];
    })
  ];
}
