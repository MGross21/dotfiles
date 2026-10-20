{ lib, ... }:
let
  workspaceBinds = lib.mergeAttrsList (
    map (
      i:
      let
        key = toString (lib.mod i 10);
        ws = toString i;
      in
      {
        "alt-${key}" = "workspace ${ws}";
        "alt-shift-${key}" = "move-node-to-workspace --focus-follows-window ${ws}";
        "alt-ctrl-${key}" = "move-node-to-workspace ${ws}";
      }
    ) (lib.range 1 10)
  );
in
{
  services.aerospace = {
    enable = true;
    settings = {
      gaps = {
        inner = {
          horizontal = 0;
          vertical = 0;
        };
        outer = {
          left = 0;
          right = 0;
          top = 0;
          bottom = 0;
        };
      };

      mode.main.binding = workspaceBinds // {
        alt-enter = "exec-and-forget open -na Ghostty";
        alt-f = "exec-and-forget open -na Firefox";
        alt-e = "exec-and-forget open ~";
        alt-c = "close";
        alt-v = "layout floating tiling";
        alt-o = "layout tiles horizontal vertical";

        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";

        alt-shift-left = "resize width -50";
        alt-shift-right = "resize width +50";
        alt-shift-up = "resize height -50";
        alt-shift-down = "resize height +50";

        alt-s = "workspace S";
        alt-shift-s = "move-node-to-workspace S";
      };
    };
  };
}
