{ pkgs, ... }:
{
  programs.git.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
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
      source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
      source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
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

      if command -v fzf >/dev/null 2>&1; then
        source <(fzf --zsh 2>/dev/null) 2>/dev/null
      fi

      if command -v zoxide >/dev/null 2>&1; then
        eval "$(zoxide init zsh --cmd cd 2>/dev/null)"
      fi

      if command -v uv >/dev/null 2>&1; then
        eval "$(uv generate-shell-completion zsh 2>/dev/null)"
      fi

      if command -v uvx >/dev/null 2>&1; then
        eval "$(uvx --generate-shell-completion zsh 2>/dev/null)"
      fi

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

    shellAliases = {
      zshrc = "$EDITOR ~/.zshrc";
      reload = "source ~/.\${SHELL##*/}rc";

      kver = "uname -rs";
      pls = "sudo $(fc -ln -1)";
      c = "clear";
      ".." = "cd ..";
      "..." = "cd ../..";
      "c-" = "cd - >/dev/null";

      mv = "mv -vi";
      cp = "cp -vir";
      rm = "rm -Ivr --preserve-root";
      mkdir = "mkdir -pv";
      ren = "mv -vi --no-copy";
      rmdir = "rmdir -v";
      grep = "rg --smart-case --hidden --color=auto";
      find = "fd --hidden --exclude .git";
      cat = "bat --paging=auto --style=plain --color=always --theme=ansi";
      bat = "bat";
      ping = "ping -c 3";

      ls = "eza --color=auto --icons";
      la = "eza -a --color=auto --icons";
      ll = "eza -lah --color=auto --icons";
      tree = "eza --tree --level=3 --color=auto --icons";

      vim = "$EDITOR";
      vi = "$EDITOR";
      v = "$EDITOR";
      sv = "sudo $EDITOR";

      gs = "git status -sb";
      ga = "git add";
      gaa = "git add -A";
      gc = "git commit";
      gcm = "git commit -m";
      gcam = "git commit -am";
      gco = "git switch";
      gcom = "git switch main 2>/dev/null || git switch master 2>/dev/null";
      gcob = "git switch -c";
      gbd = "git branch -d";
      gbD = "git branch -D";
      gbl = "git branch -al --sort=-committerdate --sort=refname --column";
      gdiff = "git diff";
      gundo = "git reset --soft HEAD~1";
      grh = "git reset HEAD";
      grhh = "git reset --hard HEAD";
      gf = "git fetch --all --prune --prune-tags --progress";
      gp = "git push";
      gpu = "git pull";
      gpuo = "git pull origin";
      gst = "git stash";
      gtag = "git tag";
      gtags = "git tag -l";
      gcp = "git cherry-pick";
      grl = "git reflog";
      gl = "git log --oneline --graph --all";
      gllg = "git log --oneline --graph --decorate --all";
      groot = "git rev-parse --show-toplevel";

      sysen = "sudo systemctl enable";
      sysstart = "sudo systemctl start";
      sysrestart = "sudo systemctl restart";
      sysstop = "sudo systemctl stop";
      sysdisable = "sudo systemctl disable";
      reboot = "systemctl reboot";
      reboot-bios = "systemctl reboot --firmware-setup";
      shutdown = "systemctl poweroff";
      services = "systemctl list-unit-files --type=service --no-pager";
      userservices = "systemctl --user list-unit-files --type=service";
      syslog = "journalctl -f";
      bootlog = "journalctl -b";

      nixupdate = "sudo nixos-rebuild switch --upgrade";
      nixbuild = "sudo nixos-rebuild switch";
      nixrollback = "sudo nixos-rebuild switch --rollback";
      nixgc = "sudo nix-collect-garbage --delete-older-than 7d";

      forcekill = "killall -9";
      psg = "ps aux | grep -v grep | grep -i";
      topmem = "ps auxf | sort -nr -k 4 | head -10";
      topcpu = "ps auxf | sort -nr -k 3 | head -10";
      disks = "lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE,LABEL";
      usage = "df -hT | grep '^/dev/'";
      ports = "ss -tulwn";
      listening = "ss -tlnp";
      myip = "curl -s ifconfig.me";
      localip = "ip route get 1.1.1.1 | awk '{print $7; exit}'";

      sf = "fastfetch";

      wifi = "nmcli device wifi";
      wifireload = "nmcli radio wifi off && nmcli radio wifi on";
      wifilist = "nmcli device wifi list";
      netdevices = "nmcli device status";

      volup = "pactl set-sink-volume @DEFAULT_SINK@ +5%";
      voldown = "pactl set-sink-volume @DEFAULT_SINK@ -5%";
      mute = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
      micmute = "pactl set-source-mute @DEFAULT_SOURCE@ toggle";

      python = "uv python";
      pip = "uv pip --require-virtualenv";
      pycompile = "uv python -m py_compile";
      uvenv = "uv venv --clear --no-managed-python && source ./.venv/bin/activate";
      uva = "uv add";
      uvad = "uv add --dev";
      uvs = "uv sync -U --all-extras --all-groups --active --no-install-package uv";
      uvl = "uv lock";
      uvr = "uv run";
      uvx = "uvx --no-managed-python";

      cc = "claude";
      gem = "gemini-cli";
    };
  };

  environment.shells = with pkgs; [ zsh ];
  users.defaultUserShell = pkgs.zsh;

  environment.systemPackages = with pkgs; [
    # Core utilities
    networkmanager
    openvpn
    sudo-rs
    git
    wget
    zip
    unzip
    rsync
    curl

    # Shell and terminal workflow
    zsh
    tmux
    zsh-completions
    zsh-syntax-highlighting
    zsh-autosuggestions
    zsh-history-substring-search

    # Terminal utilities
    gh
    less
    fzf
    zoxide
    neovim
    htop
    btop
    nvtopPackages.nvidia
    powertop
    fastfetch
    eza
    bat
    fd
    ripgrep
    speedtest-cli
    poppler
    poppler_data
    vivid
    cava
    docker
    docker-compose
    man-db
    tldr
    bluetui

    # Development toolchain
    rustc
    rustup
    rust-analyzer
    clang
    llvm
    cmake
    uv
    nodejs
    kotlin
    ktlint
    gradle
    jdk
    # cudatoolkit
    # unstable.ollama-cuda

    # Media/audio CLI utilities
    ffmpeg
    ffmpeg-full
    vulkan-tools
    pipewire
    wireplumber
    pamixer
    alsa-utils
    claude-code
    clipse


    nixfmt
    neovim
    efibootmgr
    python315
    python314
    cargo

    # Android CLI
    android-tools
  ];
}
