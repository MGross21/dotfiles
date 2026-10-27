{ config, ... }:
let
  c = config.theming.colors;
in
{
  programs.cava = {
    enable = true;
    settings = {
      general = {
        bars = 0;
        framerate = 60;
        autosens = 1;
        lower_cutoff_freq = 50;
        higher_cutoff_freq = 10000;
      };
      input = {
        method = "pulse";
        source = "auto";
      };
      output = {
        method = "noncurses";
        synchronized_sync = 1;
      };
      color = {
        gradient = 1;
        gradient_color_1 = ''"${c.red}"'';
        gradient_color_2 = ''"${c.green}"'';
        gradient_color_3 = ''"${c.yellow}"'';
        gradient_color_4 = ''"${c.blue}"'';
        gradient_color_5 = ''"${c.magenta}"'';
        gradient_color_6 = ''"${c.cyan}"'';
        background = "default";
      };
      smoothing.noise_reduction = 77;
    };
  };
}
