{ pkgs, ... }:
{
  programs.fzf = {
    fuzzyCompletion = true;
    keybindings = true;
  };

  programs.direnv = {
    enable = true;
    silent = true;
  };

  programs.zoxide = {
    enable = true;
    flags = [
      "--cmd"
      "cd"
    ];
    enableZshIntegration = true;
  };

  environment.sessionVariables = {
    EDITOR = "nvim";
    PAGER = "less";
    LESS = "-R -i -w -M -z-4";
    # ANDROID_SDK_ROOT = "/opt/android-sdk";
    CLICOLOR = "1";
    COLORTERM = "truecolor";
    FZF_DEFAULT_COMMAND = "fd --type f --follow --exclude .git --exclude node_modules --exclude __pycache__ --exclude .venv";
    FZF_CTRL_T_COMMAND = "fd --follow --exclude .git --exclude node_modules --exclude __pycache__ --exclude .venv";
    FZF_ALT_C_COMMAND = "fd --type d --follow --exclude .git --exclude node_modules --exclude __pycache__ --exclude .venv";
    FZF_DEFAULT_OPTS = "--height=~80% --layout=reverse --border --color=fg:-1,bg:-1,hl:4 --color=fg+:7,bg+:0,hl+:5 --color=info:4,prompt:1,pointer:2,marker:3,spinner:6,header:8";
    FZF_CTRL_T_OPTS = "--preview 'bat --style=numbers --color=always --line-range :100 {}' --bind 'ctrl-/:toggle-preview'";
    FZF_CTRL_R_OPTS = "--preview 'echo {}' --preview-window=up:3";
    FZF_ALT_C_OPTS = "--preview 'tree -C {} | head -50'";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions = {
      enable = true;
      highlightStyle = "fg=8";
      strategy = [
        "history"
        "completion"
        "match_prev_cmd"
      ];
      async = true;
    };
    syntaxHighlighting = {
      enable = true;
      highlighters = [
        "main"
        "brackets"
        "pattern"
        "cursor"
        "regexp"
        "root"
        "line"
      ];
    };
    histFile = "$HOME/.zsh_history";
    histSize = 50000;

    setOptions = [
      "HIST_IGNORE_ALL_DUPS"
      "HIST_REDUCE_BLANKS"
      "INC_APPEND_HISTORY"
      "SHARE_HISTORY"
      "HIST_IGNORE_SPACE"
      "HIST_VERIFY"
      "AUTO_CD"
      "AUTO_PUSHD"
      "PUSHD_IGNORE_DUPS"
      "PUSHD_SILENT"
      "EXTENDED_GLOB"
      "GLOB_DOTS"
      "NO_NOMATCH"
      "PROMPT_SUBST"
      "INTERACTIVE_COMMENTS"
      "NO_CLOBBER"
      "IGNORE_EOF"
      "CORRECT"
      "NO_BEEP"
      "MULTIOS"
      "NOTIFY"
    ];

    promptInit = ''
      autoload -Uz vcs_info
      zstyle ':vcs_info:*' enable git
      zstyle ':vcs_info:git:*' formats ':%b'
      zstyle ':vcs_info:git:*' actionformats ' [%b|%a]'
      precmd() { vcs_info; }

      autoload -Uz colors && colors
      PROMPT='%F{blue}%1~%f%F{magenta}''${vcs_info_msg_0_}%f %# '
    '';

    interactiveShellInit = ''
      [[ -f "$HOME/.paths" ]] && source "$HOME/.paths"

      if command -v vivid >/dev/null 2>&1; then
        _vivid_theme="''${VIVID_THEME:-tomorrow-night-burns}"
        if [[ "$TERM" == "linux" ]]; then
          export LS_COLORS="$(vivid -m 8-bit generate "$_vivid_theme")"
        else
          export LS_COLORS="$(vivid generate "$_vivid_theme")"
        fi
        unset _vivid_theme
      fi

      if [[ -n "$TMUX" ]]; then
        export TERM=tmux-256color
      elif [[ "$TERM" == "xterm" ]] || [[ "$TERM" == "xterm-color" ]]; then
        export TERM=xterm-256color
      fi

      source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh

      bindkey -e

      unsetopt CORRECT_ALL
      CORRECT_IGNORE=('_*' '.*')

      [[ ! -d ~/.cache/zsh ]] && mkdir -p ~/.cache/zsh

      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list \
        'm:{a-zA-Z}={A-Za-z}' \
        'r:|?=**' \
        'l:|=* r:|=*'
      zstyle ':completion:*:descriptions' format '[%d]'
      zstyle ':completion:*' list-colors ''${(s.:.)LS_COLORS}
      zstyle ':completion:*' group-name ""
      zstyle ':completion:*:*:kill:*' list-colors '=(#b) #([0-9]#)*( *[a-z])*=34=31=33'
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path ~/.cache/zsh

      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down
      bindkey '^P' history-substring-search-up
      bindkey '^N' history-substring-search-down

      if command -v tailscale >/dev/null 2>&1; then
        ares() {
          if ! systemctl is-active --quiet tailscaled.service; then
            sudo systemctl start tailscaled.service
          fi

          if ! tailscale status | grep -q "100."; then
            sudo tailscale up
          fi

          ssh ares
        }
      fi
      if command -v uv >/dev/null 2>&1; then
        eval "$(uv generate-shell-completion zsh 2>/dev/null)"
      fi

      if command -v uvx >/dev/null 2>&1; then
        eval "$(uvx --generate-shell-completion zsh 2>/dev/null)"
      fi

      sshe() {
        local host="$1"
        local local_tmp remote_tmp
        local_tmp=$(mktemp)
        remote_tmp="/tmp/.aliases_$$"
        alias | sed 's/^/alias /' >| "$local_tmp"
        scp -q "$local_tmp" "$host:$remote_tmp"
        rm -f "$local_tmp"
        ssh -t "$host" "
          if command -v zsh >/dev/null 2>&1; then
            d=\$(mktemp -d)
            printf '%s\n' 'source \$HOME/.zshrc 2>/dev/null' 'source $remote_tmp' > \"\$d/.zshrc\"
            ZDOTDIR=\$d zsh
            rm -rf \"\$d\"
          else
            bash --init-file $remote_tmp
          fi
          rm -f $remote_tmp
        "
      }

      [[ $TERM == "dumb" ]] && unsetopt zle && PS1='$ '

      autoload -U add-zsh-hook

      _auto_venv() {
        local target_venv=""
        local dir="$PWD"

        while [[ "$dir" != "/" ]]; do
          if [[ -f "$dir/.venv/bin/activate" ]]; then
            target_venv="$dir/.venv"
            break
          fi
          dir="''${dir:h}"
        done

        if [[ -n "$target_venv" ]]; then
          [[ "$VIRTUAL_ENV" != "$target_venv" ]] && source "$target_venv/bin/activate"
        elif [[ -n "$VIRTUAL_ENV" ]]; then
          deactivate 2>/dev/null
        fi
      }

      add-zsh-hook chpwd _auto_venv
      _auto_venv
    '';

  };

  environment.shells = with pkgs; [ zsh ];
  users.defaultUserShell = pkgs.zsh;
}
