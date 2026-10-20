{ ... }:
{
  home-manager.sharedModules = [
    {
      programs.ghostty.settings = {
        # hyprglass gives no text contrast on this wallpaper, so the cell background carries it.
        background-opacity = 0.35;
        # hyprglass sets noblur on every window it glasses.
        background-blur = false;

        gtk-single-instance = true;
        gtk-quick-terminal-namespace = "terminal";
      };
    }
  ];
}
