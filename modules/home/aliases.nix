{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config) dev programs;
in
{
  home.shellAliases = lib.mkMerge [
    {
      # Shell
      zshrc = "$EDITOR ${config.dotfiles.dir}/modules/home/shell.nix";
      reload = "exec \"$SHELL\"";

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
      ping = "ping -c 3";
      dd = "dd bs=4M status=progress conv=fsync";
      bc = "bc -ql";

      # Editor
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
      gcom = "git switch \"$(git rev-parse --abbrev-ref origin/HEAD | cut -d/ -f2-)\"";
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
      grbom = "git fetch origin && git rebase origin/main";
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
      nixsize = "nix path-info -Sh";
      search = "nix-search-tv print | fzf --preview 'nix-search-tv preview {}' --scheme history";

      # Diagnostics and network
      largestfiles = "dust -n 20 /";
      largestdirs = "ncdu /";
      forcekill = "killall -9";
      psg = "pgrep -afi";
      topmem = "ps aux --sort=-%mem | head -11";
      topcpu = "ps aux --sort=-%cpu | head -11";
      myip = "curl -s ifconfig.me";
      users = "w -h | awk '{print \$1}' | sort | uniq | wc -l";
      speedtest = "speedtest-cli --simple --secure | column -t";

      # Tool shortcuts
      cc = "claude";
    }

    (lib.mkIf programs.ripgrep.enable { grep = "rg"; })
    (lib.mkIf programs.fd.enable { find = "fd"; })
    (lib.mkIf programs.bat.enable { cat = "bat --paging=never"; })
    (lib.mkIf programs.eza.enable {
      ll = "eza -lah";
      tree = "eza --tree --level=3";
    })
    (lib.mkIf programs.fastfetch.enable { sf = "fastfetch"; })

    (lib.mkIf dev.python.enable {
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
      uvi = "uv init --vcs git --author-from git --no-readme --no-description --no-package --bare";
      activate = "source $PWD/.venv/bin/activate";
    })

    (lib.mkIf dev.rust.enable {
      cr = "cargo run";
      cb = "cargo build";
      cbr = "cargo build --release";
      ctest = "cargo test";
      cdoc = "cargo doc --open --no-deps";
      cfmt = "cargo fmt";
    })

    (lib.mkIf dev.android.enable {
      adevices = "adb devices -l";
      ainstall = "adb install -r";
      auninstall = "adb uninstall";
      areboot = "adb reboot";
      akill = "adb kill-server";
      alisten = "adb logcat";
      ascreenshot = "adb exec-out screencap -p > ~/Pictures/android/adb_screenshot_$(date +%Y%m%d_%H%M%S).png";
      als = "adb shell ls";
    })

    (lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      disks = "lsblk -o NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE,LABEL";
      usage = "df -hT | grep '^/dev/'";
      ports = "ss -tulwn";
      listening = "ss -tlnp";
      localip = "ip route get 1.1.1.1 | awk '{print $7; exit}'";
      devicekill = "fuser -k -9";
      lastdevice = "ls -tr1 /dev/tty* | tail -n 1";
    })
  ];
}
