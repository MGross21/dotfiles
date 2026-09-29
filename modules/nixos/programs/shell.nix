{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = [
    (pkgs.runCommand "uvx-zsh-completion"
      {
        nativeBuildInputs = [
          pkgs.uv
          pkgs.installShellFiles
        ];
      }
      ''
        export HOME=$TMPDIR
        installShellCompletion --cmd uvx --zsh <(uvx --generate-shell-completion zsh)
      ''
    )
  ]
  ++ lib.optional config.services.tailscale.enable (
    pkgs.writeShellApplication {
      name = "ares";
      runtimeInputs = [
        pkgs.tailscale
        pkgs.openssh
      ];
      text = ''
        tailscale status >/dev/null 2>&1 || sudo tailscale up
        exec ssh ares
      '';
    }
  );

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_state$git_status$cmd_duration$jobs$line_break$nix_shell$python$character";
      directory = {
        style = "blue";
        truncation_length = 3;
      };
      git_branch = {
        format = "[$branch]($style)";
        style = "bright-black";
      };
      git_state = {
        format = " \\([$state( $progress_current/$progress_total)]($style)\\)";
        style = "bright-black";
      };
      # Zero-width symbols collapse every change type into a single "*".
      git_status = {
        format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](218)( $ahead_behind$stashed)]($style) ";
        style = "cyan";
        conflicted = "​";
        untracked = "​";
        modified = "​";
        staged = "​";
        renamed = "​";
        deleted = "​";
        stashed = "≡";
      };
      cmd_duration = {
        format = "[$duration]($style) ";
        style = "yellow";
      };
      jobs = {
        format = "[$symbol$number]($style) ";
        symbol = "✦";
        style = "bright-black";
      };
      nix_shell = {
        format = "[❄ $name]($style) ";
        style = "blue";
      };
      python = {
        format = "[$virtualenv]($style) ";
        style = "bright-black";
        detect_extensions = [ ];
        detect_files = [ ];
        detect_folders = [ ];
      };
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
        vimcmd_symbol = "[❮](green)";
      };
    };
  };

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
    VIRTUAL_ENV_DISABLE_PROMPT = "1";
    COLORTERM = "truecolor";
    FZF_DEFAULT_COMMAND = "fd --type f --follow --exclude .git --exclude node_modules --exclude __pycache__ --exclude .venv";
    FZF_CTRL_T_COMMAND = "fd --follow --exclude .git --exclude node_modules --exclude __pycache__ --exclude .venv";
    FZF_ALT_C_COMMAND = "fd --type d --follow --exclude .git --exclude node_modules --exclude __pycache__ --exclude .venv";
    FZF_DEFAULT_OPTS = "--height=~80% --layout=reverse --border --color=fg:-1,bg:-1,hl:4 --color=fg+:7,bg+:0,hl+:5 --color=info:4,prompt:1,pointer:2,marker:3,spinner:6,header:8";
    FZF_CTRL_T_OPTS = "--preview 'bat --style=numbers --color=always --line-range :100 {}' --bind 'ctrl-/:toggle-preview'";
    FZF_CTRL_R_OPTS = "--preview 'echo {}' --preview-window=up:3";
    FZF_ALT_C_OPTS = "--preview 'eza --tree --level=2 --color=always --icons=always {} | head -50'";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableGlobalCompInit = false;
    enableLsColors = false;
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

    interactiveShellInit = ''
      autoload -Uz compinit
      _zcompdump=$HOME/.cache/zsh/zcompdump-''${''${''${:-/run/current-system}:A:t}%%-*}
      if [[ -f $_zcompdump ]]; then
        compinit -C -d $_zcompdump
      else
        mkdir -p ''${_zcompdump:h}
        rm -f ''${_zcompdump:h}/zcompdump-*(N)
        compinit -d $_zcompdump
      fi
      unset _zcompdump

      [[ $TERM == dumb ]] && unsetopt zle && PS1='$ '

      [[ -f "$HOME/.paths" ]] && source "$HOME/.paths"

      source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh

      bindkey -e

      CORRECT_IGNORE=('_*' '.*')

      zstyle ':completion:*' menu select
      zstyle ':completion:*' matcher-list \
        'm:{a-zA-Z}={A-Za-z}' \
        'r:|?=**' \
        'l:|=* r:|=*'
      zstyle ':completion:*:descriptions' format '[%d]'
      zstyle ':completion:*' list-colors ""
      zstyle ':completion:*' group-name ""
      zstyle ':completion:*:*:kill:*' list-colors '=(#b) #([0-9]#)*( *[a-z])*=34=31=33'
      zstyle ':completion:*' use-cache on
      zstyle ':completion:*' cache-path ~/.cache/zsh

      bindkey '^[[A' history-substring-search-up
      bindkey '^[[B' history-substring-search-down
      bindkey '^P' history-substring-search-up
      bindkey '^N' history-substring-search-down

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

  users.defaultUserShell = pkgs.zsh;
}
