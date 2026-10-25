{ lib, pkgs, ... }:
{
  home.shellAliases = {
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

    # Nix
    nixgc = "nh clean all --keep 2 --no-direnv";
    nixhash = "nix-prefetch-url --unpack --type sha256";
    search = "nix-search-tv print | fzf --preview 'nix-search-tv preview {}' --scheme history";

    # Diagnostics and network
    largestfiles = "dust -n 20 /";
    largestdirs = "ncdu /";
    forcekill = "killall -9";
    psg = "ps aux | grep -v grep | grep -i";
    topmem = "ps auxf | sort -nr -k 4 | head -10";
    topcpu = "ps auxf | sort -nr -k 3 | head -10";
    myip = "curl -s ifconfig.me";
    users = "w -h | awk '{print \$1}' | sort | uniq | wc -l";
    speedtest = "speedtest-cli --simple --secure | column -t";

    # Tool shortcuts
    sf = "fastfetch";
    gem = "gemini";
    cc = "claude";

    # Python and uv
    p = "python";
    pip = "uv pip";
    pycompile = "python -m py_compile";
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

    # Rust
    cargo = "cargo --color=auto";
    cr = "cargo run";
    cb = "cargo build";
    cbr = "cargo build --release";
    ctest = "cargo test";
    cdoc = "cargo doc --open --no-deps";
    cfmt = "cargo fmt";

    # Android
    adevices = "adb devices -l";
    ainstall = "adb install -r";
    auninstall = "adb uninstall";
    areboot = "adb reboot";
    akill = "adb kill-server";
    alisten = "adb logcat";
    ascreenshot = "adb exec-out screencap -p > ~/Pictures/android/adb_screenshot_$(date +%Y%m%d_%H%M%S).png";
    als = "adb shell ls";
    ascii = "ascii-image-converter";
  }
  // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    disks = "lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE,LABEL";
    usage = "df -hT | grep '^/dev/'";
    ports = "ss -tulwn";
    listening = "ss -tlnp";
    localip = "ip route get 1.1.1.1 | awk '{print $7; exit}'";
    devicekill = "fuser -k -9";
    lastdevice = "ls -tr1 /dev/tty* | tail -n 1";
  };
}
