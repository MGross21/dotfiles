{ ... }:
{
  home-manager.sharedModules = [
    {
      programs.ghostty.settings = {
        background-opacity = 0.85;
        background-blur = 20;

        macos-icon = "glass";
        macos-window-buttons = "hidden";
        macos-titlebar-style = "transparent";
        macos-titlebar-proxy-icon = "hidden";
        macos-auto-secure-input = true;
        macos-secure-input-indication = true;
        quick-terminal-screen = "mouse";
      };
    }
  ];
}
