{ config, lib, ... }:
let
  desktop = config.desktop.enable;
  hyprland = desktop && config.desktop.environment == "hyprland";
in
{
  home-manager.sharedModules = [
    {
      home.shellAliases = lib.mkMerge [
        {
          # System management
          sc = "systemctl";
          scu = "systemctl --user";
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
          nixwhy = "nix why-depends /run/current-system";
          fws = if config.networking.nftables.enable then "sudo nft list ruleset" else "sudo iptables -S";

          # Hardware and network
          devices = "lsusb && lspci | less";
          wifi = "nmcli device wifi";
          wifireload = "nmcli radio wifi off && nmcli radio wifi on";
          wifilist = "nmcli device wifi list";
          netdevices = "nmcli device status";
          timezones = "timedatectl list-timezones";
          timeset = "sudo timedatectl set-time";
          timezoneset = "sudo timedatectl set-timezone";
        }

        (lib.mkIf desktop {
          # Audio
          volup = "wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+";
          voldown = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
          mute = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          micmute = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
          audiolist = "wpctl status";
          audiodevices = "wpctl inspect @DEFAULT_AUDIO_SINK@";
          soundtest = "speaker-test -c 8 -t wav";
          fontreload = "fc-cache -f";
          fonts = "fc-list : family lang=en --format=\"%{family[0]}\\n\" | sort | uniq | less";
          wlr = "env | grep -i wl";

          play = "mpv --no-terminal --force-window=yes";
          playaudio = "mpv --no-terminal --force-window=no";
          camera = "mpv av://v4l2:/dev/video0 --demuxer-lavf-format=v4l2 --demuxer-lavf-o=video_size=1280x720,framerate=30,input_format=mjpeg,use_libv4l2=1 --profile=low-latency --untimed --no-cache --vo=gpu --gpu-context=\${XDG_SESSION_TYPE:-wayland} --osc=no --osd-level=0 --msg-level=ffmpeg=no,v4l2=no --screenshot-directory=$HOME/Pictures/camera 2>/dev/null";
        })

        (lib.mkIf hyprland {
          hyprreload = "hyprctl reload";
          hyprlog = "journalctl --user -u wayland-wm@hyprland.desktop.service -f";
          hyprlogs = "tail -f /run/user/$UID/hypr/*/hyprland.log";
          hyprconfig = "$EDITOR $HOME/.config/hypr/";
          monitors = "hyprctl monitors all";
          logout = "uwsm stop || hyprctl dispatch exit";
          paperreload = "systemctl --user restart hyprpaper";
          screenshot = "hyprshot -m region --clipboard-only";
        })
      ];
    }
  ];
}
