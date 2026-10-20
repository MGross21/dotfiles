{ ... }:
{
  home-manager.sharedModules = [
    (
      { config, ... }:
      let
        dir = config.dotfiles.dir;
      in
      {
        home.shellAliases = {
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

          update = "nix flake update --flake ${dir} && nh os switch ${dir}";
          nixrebuild = "nh os switch ${dir}";
          nixrollback = "sudo nixos-rebuild switch --flake path:${dir}#$(hostname) --rollback";
          nixgens = "nixos-rebuild list-generations --flake path:${dir}#$(hostname)";

          # Hardware and network
          devices = "lsusb && lspci | less";
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
          fontreload = "fc-cache -f";
          fonts = "fc-list : family lang=en --format=\"%{family[0]}\\n\" | sort | uniq | less";
          wlr = "env | grep -i wl";

          # Desktop tools
          fw = "sudo ufw";
          fws = "sudo ufw status verbose";
          zed = "zeditor";

          play = "mpv --no-terminal --force-window=yes";
          playaudio = "mpv --no-terminal --force-window=no";
          camera = "mpv av://v4l2:/dev/video0 --demuxer-lavf-format=v4l2 --demuxer-lavf-o=video_size=1280x720,framerate=30,input_format=mjpeg,use_libv4l2=1 --profile=low-latency --untimed --no-cache --vo=gpu --gpu-context=\${XDG_SESSION_TYPE:-wayland} --osc=no --osd-level=0 --msg-level=ffmpeg=no,v4l2=no --screenshot-directory=$HOME/Pictures/camera 2>/dev/null";
        };
      }
    )
  ];
}
