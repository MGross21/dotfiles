{
  config,
  lib,
  pkgs,
  ...
}:
let
  jq = lib.getExe pkgs.jq;
  configVariables = {
    "ui.window.use_client_side_decorations" = false;
  };
in
{
  config = lib.mkIf config.apps.enable {
    programs.ladybird.enable = true;

    home-manager.sharedModules = [
      (
        { config, lib, ... }:
        {
          home.activation.ladybirdSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            settings="${config.xdg.configHome}/Ladybird/Profiles/default/Settings.json"
            if merged=$({ cat "$settings" 2>/dev/null || true; } | ${jq} -s --argjson vars ${lib.escapeShellArg (builtins.toJSON configVariables)} '(.[0] // {}) | .configVariables += $vars'); then
              printf '%s\n' "$merged" | run install -Dm600 /dev/stdin "$settings"
            fi
          '';
        }
      )
    ];
  };
}
