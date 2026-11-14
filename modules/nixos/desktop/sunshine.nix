{
  config,
  lib,
  ...
}:
let
  cfg = config.desktop.sunshine;
  vd = cfg.virtualDisplay;
  hyprctl = lib.getExe' config.programs.hyprland.package "hyprctl";
  output = "SUNSHINE-1";
in
{
  options.desktop.sunshine = {
    enable = lib.mkEnableOption "Sunshine game streaming host for Moonlight";
    virtualDisplay = {
      enable = lib.mkEnableOption "a headless Hyprland output, created per stream, as the Sunshine capture source";
      mode = lib.mkOption {
        type = lib.types.str;
        default = "3840x2160@60";
        description = "Mode of the headless Hyprland output streamed to Moonlight clients.";
      };
      scale = lib.mkOption {
        type = lib.types.number;
        default = 2;
        description = "Scale of the headless Hyprland output streamed to Moonlight clients.";
      };
      workspace = lib.mkOption {
        type = lib.types.str;
        default = "name:stream";
        description = "Workspace bound to the headless Hyprland output.";
      };
    };
  };

  config = lib.mkIf (config.desktop.enable && cfg.enable) (
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = vd.enable -> config.desktop.environment == "hyprland";
            message = "desktop.sunshine.virtualDisplay requires the Hyprland desktop environment.";
          }
        ];

        services.sunshine = {
          enable = true;
          autoStart = true;
          openFirewall = true;
          settings.sunshine_name = config.networking.hostName;
          applications.apps = [
            {
              name = "Desktop";
              image-path = "desktop.png";
            }
          ];
        };
      }

      (lib.mkIf (!vd.enable) {
        services.sunshine = {
          capSysAdmin = true;
          settings.capture = "kms";
        };
      })

      (lib.mkIf vd.enable {
        services.sunshine.settings = {
          capture = "wlr";
          output_name = output;
          global_prep_cmd = builtins.toJSON [
            {
              do = "${hyprctl} output create headless ${output}";
              undo = "${hyprctl} output remove ${output}";
            }
          ];
        };

        environment.etc."hypr/monitors.lua".text = ''
          hl.monitor(${
            lib.generators.toLua { } {
              inherit output;
              inherit (vd) mode scale;
              position = "auto-right";
            }
          })
          hl.workspace_rule(${
            lib.generators.toLua { } {
              inherit (vd) workspace;
              monitor = output;
              default = true;
            }
          })
        '';
      })
    ]
  );
}
