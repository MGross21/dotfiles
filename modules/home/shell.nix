{
  config,
  lib,
  pkgs,
  ...
}:
let
  c = config.theming.colors;
  inherit (config.theming) accent;
  fdExcludes = "--follow --exclude .git --exclude node_modules --exclude __pycache__ --exclude .venv";
  homeHash = lib.head (lib.splitString "-" (baseNameOf config.home.path));

  zstyle =
    ctx: style: value:
    "zstyle ${lib.escapeShellArg ctx} ${style} ${lib.escapeShellArgs (lib.toList value)}";
  completionStyles = {
    ":completion:*" = {
      menu = "select";
      matcher-list = [
        "m:{a-zA-Z}={A-Za-z}"
        "r:|?=**"
        "l:|=* r:|=*"
      ];
      list-colors = "";
      group-name = "";
      use-cache = "on";
      cache-path = "${config.xdg.cacheHome}/zsh";
    };
    ":completion:*:descriptions".format = "[%d]";
    ":completion:*:*:kill:*".list-colors = "=(#b) #([0-9]#)*( *[a-z])*=34=31=33";
  };
  zstyles = lib.concatLines (
    lib.concatLists (lib.mapAttrsToList (ctx: lib.mapAttrsToList (zstyle ctx)) completionStyles)
  );
in
{
  home.packages = [
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
  ];

  home.sessionVariables = {
    EDITOR = "nvim";
    PAGER = "less";
    LESS = "-R -i -w -M -z-4";
    CLICOLOR = "1";
    VIRTUAL_ENV_DISABLE_PROMPT = "1";
    COLORTERM = "truecolor";
  };

  # Also writes ~/.profile, which the graphical session sources for these variables.
  programs.bash.enable = true;

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      palette = "theme";
      palettes.theme.accent = accent;
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
        format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](accent)( $ahead_behind$stashed)]($style) ";
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
        success_symbol = "[❯](accent)";
        error_symbol = "[❯](red)";
        vimcmd_symbol = "[❮](green)";
      };
    };
  };

  programs.fzf = {
    enable = true;
    defaultCommand = "fd --type f ${fdExcludes}";
    defaultOptions = [
      "--height=~80%"
      "--layout=reverse"
      "--border"
      "--color=fg:-1,bg:-1,hl:4"
      "--color=fg+:7,bg+:0,hl+:5"
      "--color=info:4,prompt:1,pointer:2,marker:3,spinner:6,header:8"
    ];
    fileWidget = {
      command = "fd ${fdExcludes}";
      options = [
        "--preview 'bat --style=numbers --color=always --line-range :100 {}'"
        "--bind 'ctrl-/:toggle-preview'"
      ];
    };
    changeDirWidget = {
      command = "fd --type d ${fdExcludes}";
      options = [
        "--preview 'eza --tree --level=2 --color=always --icons=always {} | head -50'"
      ];
    };
    historyWidget.options = [
      "--preview 'echo {}'"
      "--preview-window=up:3"
    ];
  };

  programs.direnv = {
    enable = true;
    silent = true;
    nix-direnv.enable = true;
  };

  programs.zoxide = {
    enable = true;
    options = [
      "--cmd"
      "cd"
    ];
  };

  programs.zsh = {
    enable = true;
    defaultKeymap = "emacs";

    enableCompletion = true;
    # Dump is keyed on the user and system profiles so it regenerates after a switch.
    completionInit = ''
      autoload -Uz compinit
      _zcompdump=$HOME/.cache/zsh/zcompdump-${homeHash}-''${''${''${:-/run/current-system}:A:t}%%-*}
      if [[ -f $_zcompdump ]]; then
        compinit -C -d $_zcompdump
      else
        mkdir -p ''${_zcompdump:h}
        rm -f ''${_zcompdump:h}/zcompdump-*(N)
        compinit -d $_zcompdump
      fi
      unset _zcompdump
    '';

    autosuggestion = {
      enable = true;
      highlight = "fg=8";
      strategy = [
        "history"
        "completion"
        "match_prev_cmd"
      ];
    };

    syntaxHighlighting = {
      enable = true;
      highlighters = [
        "brackets"
        "pattern"
        "cursor"
        "regexp"
        "root"
        "line"
      ];
      styles =
        let
          fgAccent = "fg=${accent}";
          quoted = "fg=${c.brightYellow}";
        in
        {
          command = fgAccent;
          builtin = fgAccent;
          alias = fgAccent;
          suffix-alias = fgAccent;
          function = fgAccent;
          precommand = "${fgAccent},underline";
          reserved-word = "fg=${c.blue}";
          single-quoted-argument = quoted;
          double-quoted-argument = quoted;
          dollar-quoted-argument = quoted;
          globbing = "fg=${c.magenta}";
          history-expansion = "fg=${c.magenta}";
          comment = "fg=${c.brightBlack}";
          bracket-level-1 = "${fgAccent},bold";
          bracket-level-2 = "fg=${c.blue},bold";
          bracket-level-3 = "fg=${c.magenta},bold";
          bracket-level-4 = "${quoted},bold";
        };
    };

    historySubstringSearch = {
      enable = true;
      searchUpKey = [
        "^[[A"
        "^P"
      ];
      searchDownKey = [
        "^[[B"
        "^N"
      ];
    };

    history = {
      path = "$HOME/.zsh_history";
      size = 50000;
      save = 50000;
      ignoreAllDups = true;
      ignoreSpace = true;
      share = true;
    };

    setOptions = [
      "HIST_REDUCE_BLANKS"
      "INC_APPEND_HISTORY"
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

    localVariables = {
      CORRECT_IGNORE = [
        "_*"
        ".*"
      ];
      HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND = "bg=${accent},fg=${c.bg},bold";
      HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND = "bg=${c.red},fg=${c.bg},bold";
    };

    siteFunctions = {
      sshe = ''
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
      '';

      _auto_venv = ''
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
      '';
    };

    initContent = lib.mkMerge [
      ''
        [[ $TERM == dumb ]] && unsetopt zle && PS1='$ '

        ${zstyles}
      ''
      # After the siteFunctions autoload line.
      (lib.mkOrder 1050 ''
        autoload -U add-zsh-hook
        add-zsh-hook chpwd _auto_venv
        _auto_venv
      '')
    ];
  };
}
