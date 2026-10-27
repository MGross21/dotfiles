{
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        type = "auto";
        source = "auto";
        width = 20;
        height = 20;
      };
      modules = [
        "title"
        "separator"
        "os"
        "kernel"
        "uptime"
        "packages"
        "de"
        "wm"
        "disk"
        "break"
        "colors"
      ];
    };
  };
}
