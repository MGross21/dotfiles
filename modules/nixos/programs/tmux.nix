{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;
    baseIndex = 1;
    keyMode = "vi";
    customPaneNavigationAndResize = true;
    escapeTime = 0;
    historyLimit = 50000;
    terminal = "tmux-256color";

    # Plugin @options must be set before run-shell or the plugin reads the default.
    extraConfigBeforePlugins = ''
      set -g prefix C-Space
      set -g prefix2 C-b
      bind C-Space send-prefix

      set -g @resurrect-capture-pane-contents 'on'
      set -g @resurrect-strategy-nvim 'session'
      set -g @continuum-restore 'on'
      set -g @continuum-save-interval '10'

      set -g @thumbs-key F
      set -g @thumbs-command 'echo -n {} | wl-copy'
      set -g @thumbs-upcase-command 'tmux set-buffer -- {} && tmux paste-buffer'

      set -g @extrakto_key 'tab'
      set -g @extrakto_clip_tool 'wl-copy'
      set -g @extrakto_copy_key 'enter'
      set -g @extrakto_insert_key 'tab'

      # Must be set-environment, not a bare assignment; default F collides with tmux-thumbs.
      set-environment -g TMUX_FZF_LAUNCH_KEY "C-f"
    '';

    plugins = with pkgs.tmuxPlugins; [
      sensible
      resurrect
      continuum
      cpu
      battery
      yank
      vim-tmux-navigator
      tmux-fzf
      extrakto
      tmux-thumbs
    ];

    extraConfig = ''
      set -g mouse on
      set-option -g renumber-windows on

      set -g focus-events on
      set -ag terminal-overrides ",*:RGB"

      set -g allow-passthrough on
      set -ga update-environment TERM
      set -ga update-environment TERM_PROGRAM

      set -g detach-on-destroy off
      set -sg repeat-time 600

      unbind r
      bind r source-file /etc/tmux.conf \; display-message "Config Reloaded!"

      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "wl-copy"
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi C-v send-keys -X rectangle-toggle

      bind '"' split-window -v -c "#{pane_current_path}"
      bind % split-window -h -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"

      bind -r < swap-window -d -t -1
      bind -r > swap-window -d -t +1

      bind-key -n C-o run-shell "sesh connect \"$(
        sesh list --icons | ${pkgs.fzf}/bin/fzf-tmux -p 80%,70% \
          --no-sort --ansi --border-label ' sesh ' --prompt '⚡ '
      )\""

      set -g status-interval 15
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
