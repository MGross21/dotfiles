{
  inputs,
  lib,
  theme,
}:
{
  name = "theme-preview-${theme}";

  node = {
    specialArgs = { inherit inputs; };
    pkgsReadOnly = false;
  };

  nodes.machine =
    { config, pkgs, ... }:
    let
      wallpaper = lib.last (lib.splitString "-" (baseNameOf (import ../themes).${theme}.wallpaper));
      fetchConfig = (pkgs.formats.json { }).generate "fastfetch.json" (
        config.home-manager.users.${config.user.name}.programs.fastfetch.settings
        // {
          modules = [
            "title"
            "separator"
            "os"
            "kernel"
            "packages"
            "shell"
            {
              type = "display";
              key = "Resolution";
              format = "{width}x{height}";
            }
            "wm"
            "theme"
            "icons"
            "font"
            "cursor"
            "terminal"
            "terminalfont"
            "break"
            "colors"
          ];
        }
      );
      noise = pkgs.runCommand "preview-audio.wav" { nativeBuildInputs = [ pkgs.sox ]; } ''
        sox -n -r 48000 -c 2 $out synth 300 pinknoise synth brownnoise mix tremolo 2 60
      '';
      app =
        name: runtimeInputs: text:
        pkgs.writeShellApplication { inherit name runtimeInputs text; };
      asUser = app "as-user" [ pkgs.coreutils pkgs.util-linux ] ''
        uid=$(id -u ${config.user.name})
        exec runuser -u ${config.user.name} -- \
          env XDG_RUNTIME_DIR="/run/user/$uid" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" "$@"
      '';
    in
    {
      imports = [
        inputs.stylix.nixosModules.stylix
        inputs.disko.nixosModules.disko
        inputs.home-manager.nixosModules.home-manager
        (inputs.import-tree ../modules/system)
        (inputs.import-tree ../modules/nixos)
      ];

      theming.name = theme;
      desktop.enable = true;
      home-manager.sharedModules = [ { dotfiles.mutable = false; } ];

      networking.hostName = lib.mkForce "nixos";
      boot.plymouth.enable = lib.mkForce false;
      boot.consoleLogLevel = lib.mkForce 7;

      environment.systemPackages = [
        pkgs.jq
        asUser
        (app "hypr" [ asUser ] ''
          exec as-user hyprctl -i 0 "$@"
        '')
        (app "preview-audio" [ asUser pkgs.pipewire ] ''
          exec as-user pw-play ${noise}
        '')
        (app "preview-files" [ asUser pkgs.glib ] ''
          exec as-user gdbus call --session --dest org.freedesktop.FileManager1 \
            --object-path /org/freedesktop/FileManager1 --method org.freedesktop.FileManager1.ShowItems \
            "['file://${config.users.users.${config.user.name}.home}/Pictures/wallpapers/${wallpaper}']" ""
        '')
        (app "preview-cpu" [ pkgs.coreutils pkgs.util-linux ] ''
          tail -n +2 /proc/stat > /run/stat-rest
          touch /run/stat
          mount --bind /run/stat /proc/stat
          for ((t = 1; ; t++)); do
            { printf 'cpu  %d 0 0 %d 0 0 0 0 0 0\n' $((t * 7)) $((t * 93)); cat /run/stat-rest; } > /run/stat
            sleep 1
          done
        '')
        (app "preview-fetch" [ ] ''
          exec zsh -c "fastfetch -c ${fetchConfig}; touch /tmp/fetched; exec zsh -i"
        '')
      ];

      virtualisation = {
        memorySize = 4096;
        cores = 4;
        diskSize = 8192;
        qemu.options = [
          "-vga none"
          "-device VGA,edid=on,xres=1920,yres=1080"
          "-audiodev none,id=snd0"
          "-device intel-hda"
          "-device hda-output,audiodev=snd0"
        ];
      };
    };

  testScript = ''
    def hypr(cmd):
        return machine.succeed(f"hypr {cmd}")

    def dispatch(lua):
        hypr(f"dispatch '{lua}'")

    def freeze_clock():
        machine.succeed("date -s '2029-01-09 09:41:00'")

    def wait_clients(n):
        machine.wait_until_succeeds(f"[ $(hypr clients -j | jq length) -ge {n} ]", timeout=90)

    machine.wait_for_unit("sysinit.target")
    machine.succeed("dmesg -n 1")
    machine.execute("preview-cpu >&2 &")
    machine.wait_for_unit("display-manager.service")
    machine.sleep(3)
    machine.send_chars("mgross")
    machine.send_key("tab")
    freeze_clock()
    machine.sleep(3)
    machine.screenshot("login")

    machine.send_chars("changeme\n")
    machine.wait_until_succeeds("journalctl -b | grep -q 'qs.*Configuration Loaded'", timeout=120)
    freeze_clock()
    hypr("eval 'hl.config({ cursor = { inactive_timeout = 1 } })'")
    machine.sleep(15)
    machine.screenshot("desktop")

    freeze_clock()
    machine.execute("preview-audio >&2 &")
    hypr("eval 'hl.window_rule({ name = \"windowrule-1\", match = { class = \"^never$\" } })'")
    dispatch('hl.dsp.focus({ workspace = 2 })')
    dispatch('hl.dsp.exec_cmd("ghostty -e cava")')
    wait_clients(1)
    machine.sleep(3)
    machine.succeed("preview-files")
    wait_clients(2)
    machine.sleep(3)
    dispatch('hl.dsp.focus({ direction = "left" })')
    dispatch('hl.dsp.exec_cmd("ghostty -e preview-fetch")')
    wait_clients(3)
    machine.wait_for_file("/tmp/fetched")
    freeze_clock()
    machine.sleep(15)
    machine.screenshot("apps")
  '';
}
