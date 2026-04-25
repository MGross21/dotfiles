{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    config = {
      init.defaultBranch = "main";

      user = {
        name = "Michael Gross";
        email = "mgrossofficial@gmail.com";
      };

      core = {
        editor = "nvim";
        autocrlf = "input";
      };

      fetch.prune = true;
      pull.ff = "only";
      push.autoSetupRemote = true;
      rebase.autoStash = true;

      credential."https://github.com".helper = [
        ""
        "!/run/current-system/sw/bin/gh auth git-credential"
      ];

      credential."https://gist.github.com".helper = [
        ""
        "!/run/current-system/sw/bin/gh auth git-credential"
      ];
    };
  };

  programs.fzf = {
    fuzzyCompletion = true;
    keybindings = true;
  };

  programs.zoxide = {
    enable = true;
    flags = [ "--cmd" "cd" ];
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
    FZF_DEFAULT_OPTS = "--height=40% --layout=reverse --border --color=fg:#a1b0b8,bg:#151515,hl:#fc595f --color=fg+:#f5f5f5,bg+:#252525,hl+:#df9395 --color=info:#fc595f,prompt:#832e31,pointer:#a63c40,marker:#d3494e,spinner:#ba8586,header:#5d6f71";
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
      strategy = [ "history" "completion" "match_prev_cmd" ];
      async = true;
    };
    syntaxHighlighting = {
      enable = true;
      highlighters = [ "main" "brackets" "pattern" "cursor" "regexp" "root" "line" ];
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
        theme="tomorrow-night-burns"
        if [[ "$TERM" == "linux" ]]; then
          export LS_COLORS="$(vivid -m 8-bit generate "$theme")"
        else
          export LS_COLORS="$(vivid generate "$theme")"
        fi
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
      # Shell
      zshrc = "$EDITOR ~/.zshrc";
      reload = "source ~/.\${SHELL##*/}rc";

      # Navigation and file operations
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

      # Listing and editor
      ls = "eza --color=auto --icons";
      la = "eza -a --color=auto --icons";
      ll = "eza -lah --color=auto --icons";
      tree = "eza --tree --level=3 --color=auto --icons";
      vim = "$EDITOR";
      vi = "$EDITOR";
      v = "$EDITOR";
      sv = "sudo $EDITOR";

      # Git
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
      glg = "git log --graph --pretty=format:\"%C(yellow)%h%Creset -%C(auto)%d%Creset %s %C(blue)[%an]\" --abbrev-commit";
      gllg = "git log --oneline --graph --decorate --all";
      groot = "git rev-parse --show-toplevel";

      # System management
      sysen = "sudo systemctl enable";
      sysstart = "sudo systemctl start";
      sysrestart = "sudo systemctl restart";
      sysstop = "sudo systemctl stop";
      sysdisable = "sudo systemctl disable";
      blame = "systemd-analyze blame | less";
      chain = "systemd-analyze critical-chain | less";
      reboot = "systemctl reboot";
      reboot-bios = "systemctl reboot --firmware-setup";
      shutdown = "systemctl poweroff";
      services = "systemctl list-unit-files --type=service --no-pager";
      userservices = "systemctl --user list-unit-files --type=service";
      syslog = "journalctl -f";
      bootlog = "journalctl -b";

      update = "sudo nixos-rebuild switch --upgrade";
      nixrebuild = "sudo nixos-rebuild switch";
      nixrollback = "sudo nixos-rebuild switch --rollback";
      nixgc = "sudo nix-collect-garbage --delete-older-than 7d";

      # Diagnostics and network
      forcekill = "killall -9";
      psg = "ps aux | grep -v grep | grep -i";
      topmem = "ps auxf | sort -nr -k 4 | head -10";
      topcpu = "ps auxf | sort -nr -k 3 | head -10";
      devices = "lsusb && lspci | less";
      lastdevice = "ls -tr1 /dev/tty* | tail -n 1";
      devicekill = "fuser -k -9";
      disks = "lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE,LABEL";
      usage = "df -hT | grep '^/dev/'";
      ports = "ss -tulwn";
      listening = "ss -tlnp";
      myip = "curl -s ifconfig.me";
      localip = "ip route get 1.1.1.1 | awk '{print $7; exit}'";
      users = "w -h | awk '{print \$1}' | sort | uniq | wc -l";
      speedtest = "speedtest-cli --simple --secure | column -t";
      wifi = "nmcli device wifi";
      wifireload = "nmcli radio wifi off && nmcli radio wifi on";
      wifilist = "nmcli device wifi list";
      netdevices = "nmcli device status";
      timezones = "timedatectl list-timezones";
      timeset = "sudo timedatectl set-time";
      timezoneset = "sudo timedatectl set-timezone";

      # Audio and Wayland
      volup = "pactl set-sink-volume @DEFAULT_SINK@ +5%";
      voldown = "pactl set-sink-volume @DEFAULT_SINK@ -5%";
      mute = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
      micmute = "pactl set-source-mute @DEFAULT_SOURCE@ toggle";
      audiolist = "pactl list sinks short";
      audiodevices = "pactl list sinks";
      soundtest = "speaker-test -c 8 -t wav";
      hyprreload = "hyprctl reload";
      hyprlog = "journalctl -xe | grep Hyprland";
      hyprconfig = "$EDITOR $HOME/.config/hypr/";
      monitors = "hyprctl monitors all";
      logout = "uwsm stop || hyprctl dispatch exit";
      nightmode = "hyprsunset --temperature 3000";
      paperreload = "pkill hyprpaper; (hyprpaper & disown)";
      screenshot = "hyprshot -m region --clipboard-only";
      barreload = "pkill waybar; (waybar & disown)";
      clip = "wl-copy";
      paste = "wl-paste";
      fontreload = "fc-cache -f";
      fonts = "fc-list : family lang=en --format=\"%{family[0]}\\n\" | sort | uniq | less";
      wlr = "env | grep -i wl";

      # Firewall and tool shortcuts
      fw = "sudo ufw";
      fws = "sudo ufw status verbose";
      sf = "fastfetch";
      gem = "gemini";
      zed = "zeditor";
      cc = "claude";

      # Python and uv
      python = "uv python";
      p = "python";
      pip = "uv pip --require-virtualenv";
      pycompile = "uv python -m py_compile";
      uvenv = "uv venv --clear && source ./.venv/bin/activate";
      uva = "uv add";
      uvad = "uv add --dev";
      uvs = "uv sync -U --all-extras --all-groups --active --no-install-package uv";
      uvl = "uv lock";
      uvr = "uv run";
      uvb = "uv build --clear";
      uvvb = "uv version --bump";
      uvp = "uv publish --token '__token__'";
      uvx = "uvx";
      uvi = "uv init --vcs git --author-from git --no-readme --no-description --no-package --bare";
      activate = "source $PWD/.venv/bin/activate";

      # Rust, media, and Android
      cargo = "cargo --color=auto";
      cr = "cargo run";
      cb = "cargo build";
      cbr = "cargo build --release";
      ctest = "cargo test";
      cdoc = "cargo doc --open --no-deps";
      cfmt = "cargo fmt";

      play = "mpv --no-terminal --force-window=yes";
      playaudio = "mpv --no-terminal --force-window=no";
      camera = "mpv av://v4l2:/dev/video0 --demuxer-lavf-format=v4l2 --demuxer-lavf-o=video_size=1280x720,framerate=30,input_format=mjpeg,use_libv4l2=1 --profile=low-latency --untimed --no-cache --vo=gpu --gpu-context=\${XDG_SESSION_TYPE:-wayland} --osc=no --osd-level=0 --msg-level=ffmpeg=no,v4l2=no --screenshot-directory=$HOME/Pictures/camera 2>/dev/null";

      adevices = "adb devices -l";
      ainstall = "adb install -r";
      auninstall = "adb uninstall";
      areboot = "adb reboot";
      akill = "adb kill-server";
      alisten = "adb logcat";
      ascreenshot = "adb exec-out screencap -p > ~/Pictures/android/adb_screenshot_$(date +%Y%m%d_%H%M%S).png";
      als = "adb shell ls";
      ascii = "ascii-image-converter";
    };
  };

  environment.shells = with pkgs; [ zsh ];
  users.defaultUserShell = pkgs.zsh;

  environment.systemPackages = with pkgs; [
    # Core utilities
    openvpn
    wget
    zip
    unzip
    rsync
    curl

    # Shell and terminal workflow
    tmux
    zsh-completions
    zsh-history-substring-search

    # Terminal utilities
    gh
    less
    fzf
    neovim
    htop
    btop
    powertop
    fastfetch
    eza
    bat
    fd
    ripgrep
    speedtest-cli
    jq
    impala
    poppler
    poppler_data
    fontconfig
    vivid
    cava
    docker-compose
    man-db
    tldr
    bluetui

    # Development toolchain
    rustup
    rust-analyzer
    espflash
    gnumake
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
    ffmpeg-full
    vulkan-tools
    pamixer
    alsa-utils
    claude-code
    claude-monitor
    gemini-cli
    clipse

    nixfmt
    efibootmgr
    python3
    mpv

    # Android CLI
    android-tools
    wl-clipboard
    usbutils
    pciutils
    psmisc
    inetutils
  ];
}
