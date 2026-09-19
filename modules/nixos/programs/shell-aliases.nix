{ ... }:
{
  programs.zsh.shellAliases = {
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
    dd = "dd bs=4M status=progress conv=fsync,noerror";
    bc = "bc -ql";

    # Listing and editor
    ls = "eza --color=auto --icons=auto";
    la = "eza -a --color=auto --icons=auto";
    ll = "eza -lah --color=auto --icons=auto";
    tree = "eza --tree --level=3 --color=auto --icons=auto";
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
    gpu = "git pull --progress --multiple";
    gpuo = "git pull origin --progress --multiple";
    gst = "git stash";
    grbom = "git rebase origin/main";
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
    largestfiles = "dust -n 20 /";
    largestdirs = "ncdu /";

    update = "nix flake update --flake ~/dotfiles && nh os switch ~/dotfiles";
    nixrebuild = "nh os switch ~/dotfiles";
    nixrollback = "sudo nixos-rebuild switch --flake path:$HOME/dotfiles#$(hostname) --rollback";
    nixgens = "nixos-rebuild list-generations --flake path:$HOME/dotfiles#$(hostname)";
    nixgc = "nh clean all --keep 2";
    nixhash = "nix-prefetch-url --unpack --type sha256";
    search = "nix-search-tv print | fzf --preview 'nix-search-tv preview {}' --scheme history";

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
    hyprlogs = "tail -f /run/user/$UID/hypr/*/hyprland.log";
    hyprconfig = "$EDITOR $HOME/.config/hypr/";
    monitors = "hyprctl monitors all";
    logout = "uwsm stop || hyprctl dispatch exit";
    paperreload = "systemctl --user restart hyprpaper";
    screenshot = "hyprshot -m region --clipboard-only";
    barreload = "systemctl --user restart quickshell";
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
}
