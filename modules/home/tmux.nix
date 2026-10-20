{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.clipboard) copy;

  globalOptions = {
    renumber-windows = "on";
    allow-passthrough = "on";
    detach-on-destroy = "off";

    status-interval = 15;
    status-left-length = 40;
    status-right-length = 80;
    status-left = "#[fg=colour4,bold] #S #[fg=colour8]│ ";
    status-right = "#[fg=colour2] #{cpu_percentage} CPU #[fg=colour8]│#[fg=colour6] #{ram_percentage} RAM #[fg=colour8]│#{battery_color_fg}  #{battery_percentage} #[fg=colour8]│#[fg=colour8] %H:%M ";
    window-status-format = "#[fg=colour8] #I:#W ";
    window-status-current-format = "#[fg=colour7,bold] #I:#W ";

    status-style = "bg=colour0,fg=colour8";
    pane-border-style = "fg=colour8";
    pane-active-border-style = "fg=colour4";
    message-style = "bg=colour0,fg=colour3";
  };
in
{
  home.packages = [ pkgs.sesh ];

  programs.tmux = {
    enable = true;
    baseIndex = 1;
    keyMode = "vi";
    customPaneNavigationAndResize = true;
    escapeTime = 0;
    historyLimit = 50000;
    terminal = "tmux-256color";
    mouse = true;
    focusEvents = true;

    # Each plugin's @options must precede its run-shell or the plugin reads the default.
    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = sensible;
        extraConfig = ''
          set -g prefix C-Space
          set -g prefix2 C-b
          bind C-Space send-prefix
        '';
      }
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-strategy-nvim 'session'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '10'
        '';
      }
      cpu
      battery
      yank
      vim-tmux-navigator
      {
        plugin = tmux-fzf;
        # Must be set-environment, not a bare assignment; default F collides with tmux-thumbs.
        extraConfig = ''
          set-environment -g TMUX_FZF_LAUNCH_KEY "C-f"
        '';
      }
      {
        plugin = extrakto;
        extraConfig = ''
          set -g @extrakto_key 'tab'
          set -g @extrakto_clip_tool '${copy}'
          set -g @extrakto_copy_key 'enter'
          set -g @extrakto_insert_key 'tab'
        '';
      }
      {
        plugin = tmux-thumbs;
        extraConfig = ''
          set -g @thumbs-key F
          set -g @thumbs-command 'echo -n {} | ${copy}'
          set -g @thumbs-upcase-command 'tmux set-buffer -- {} && tmux paste-buffer'
        '';
      }
    ];

    extraConfig = ''
      ${lib.concatLines (
        lib.mapAttrsToList (k: v: "set -g ${k} ${lib.escapeShellArg (toString v)}") globalOptions
      )}
      set -ag terminal-overrides ",*:RGB"
      set -ga update-environment TERM
      set -ga update-environment TERM_PROGRAM
      set -sg repeat-time 600

      unbind r
      bind r source-file ${config.xdg.configHome}/tmux/tmux.conf \; display-message "Config Reloaded!"

      bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "${copy}"
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
    '';
  };
}
