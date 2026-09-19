{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    keyMode = "vi";
    customPaneNavigationAndResize = true;
    escapeTime = 0;
    historyLimit = 10000;
    terminal = "tmux-256color";
    plugins = with pkgs.tmuxPlugins; [
      sensible
      resurrect
      continuum
      cpu
      battery
      yank
    ];
    extraConfig = ''
      set -g mouse on
      set-option -g renumber-windows on

      set -g focus-events on
      set -ag terminal-overrides ",*:RGB"

      set -g @continuum-restore 'on'
      set -g @continuum-save-interval '10'

      unbind r
      bind r source-file /etc/tmux.conf \; display-message "Config Reloaded!"

      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "wl-copy"

      set -g status-interval 5
      set -g status-left-length 40
      set -g status-right-length 80

      set -g status-left "#[fg=colour4,bold] #S #[fg=colour8]│ "
      set -g status-right "#[fg=colour2] #{cpu_percentage} CPU #[fg=colour8]│#[fg=colour6] #{ram_percentage} RAM #[fg=colour8]│#{battery_color_fg}  #{battery_percentage} #[fg=colour8]│#[fg=colour8] %H:%M "

      set -g window-status-format "#[fg=colour8] #I:#W "
      set -g window-status-current-format "#[fg=colour7,bold] #I:#W "

      set -g status-style "bg=colour0,fg=colour8"
      set -g pane-border-style "fg=colour8"
      set -g pane-active-border-style "fg=colour4"
      set -g message-style "bg=colour0,fg=colour3"
    '';
  };
}
