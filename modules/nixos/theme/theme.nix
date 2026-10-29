{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  data = (import ../../../themes).${config.theming.name};
  gtkTheme = "Materia-dark-compact";
  iconTheme = "Papirus-Dark";
  c = config.theming.colors;
  rm = lib.removePrefix "#";
  ly = c: "0x00${rm c}";

  qtFont = font: ''"${font.name},${toString config.stylix.fonts.sizes.applications}"'';
  qt6ctColors =
    let
      b = config.lib.stylix.colors;
      # QPalette::ColorRole order.
      roles =
        text:
        lib.concatMapStringsSep ", " (hex: "#ff${hex}") [
          text
          b.base01
          b.base03
          b.base02
          b.base00
          b.base02
          text
          b.base07
          text
          b.base01
          b.base00
          "000000"
          (rm config.theming.accent)
          b.base00
          b.base0D
          b.base0E
          b.base02
          b.base00
          b.base01
          b.base05
          b.base04
        ];
    in
    pkgs.writeText "stylix.conf" (
      lib.generators.toINI { } {
        ColorScheme = {
          active_colors = roles b.base05;
          inactive_colors = roles b.base05;
          disabled_colors = roles b.base03;
        };
      }
    );
in
{
  config = {
    environment.systemPackages = [ (pkgs.papirus-icon-theme.override { color = data.folders; }) ];

    environment.sessionVariables = {
      XCURSOR_THEME = config.stylix.cursor.name;
      XCURSOR_SIZE = toString config.stylix.cursor.size;
    };

    home-manager.sharedModules = [
      {
        home.pointerCursor = {
          enable = true;
          inherit (config.stylix.cursor) package name size;
        };
        services.xsettingsd = {
          enable = config.desktop.enable && config.desktop.environment == "hyprland";
          settings = {
            "Net/ThemeName" = gtkTheme;
            "Net/IconThemeName" = iconTheme;
            "Gtk/CursorThemeName" = config.stylix.cursor.name;
            "Gtk/CursorThemeSize" = config.stylix.cursor.size;
            "Net/SoundThemeName" = "freedesktop";
            "Net/EnableEventSounds" = true;
            "Net/EnableInputFeedbackSounds" = false;
            "Xft/Antialias" = true;
            "Xft/Hinting" = true;
            "Xft/HintStyle" = "hintslight";
            "Xft/RGBA" = "rgb";
          };
        };
        systemd.user.services.xsettingsd.Unit.ConditionEnvironment = "DISPLAY";
        home.pointerCursor.gtk.enable = config.desktop.enable;
        gtk = lib.mkIf config.desktop.enable {
          enable = true;
          theme = {
            name = gtkTheme;
            package = pkgs.materia-theme;
          };
          iconTheme.name = iconTheme;
          font = {
            name = "Ubuntu";
            size = 11;
          };
          gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
          gtk4 = {
            theme = {
              name = gtkTheme;
              package = pkgs.materia-theme;
            };
            extraConfig.gtk-application-prefer-dark-theme = true;
          };
        };
        dconf.settings."org/gnome/desktop/interface" = {
          cursor-theme = config.stylix.cursor.name;
          cursor-size = config.stylix.cursor.size;
          color-scheme = "prefer-dark";
        };
        xdg.configFile."qt6ct/qt6ct.conf".text = lib.generators.toINI { } {
          Appearance = {
            custom_palette = true;
            color_scheme_path = "${qt6ctColors}";
            icon_theme = iconTheme;
            standard_dialogs = "default";
            style = "Fusion";
          };
          Fonts = {
            general = qtFont config.stylix.fonts.sansSerif;
            fixed = qtFont config.stylix.fonts.monospace;
          };
        };
      }
    ];

    stylix = {
      enable = true;
      base16Scheme = data.yaml;
      image = lib.mkDefault data.wallpaper;
      polarity = "dark";
      cursor = lib.mkDefault {
        package = pkgs.apple-cursor;
        name = "macOS";
        size = 24;
      };
      fonts = { inherit (config.theming.fonts) sansSerif monospace serif; };
      targets = {
        console.enable = true;
        regreet.enable = false; # unused DM; silences a rename warning
      };
    };

    services.displayManager.ly.settings = {
      bg = ly c.bg;
      fg = ly c.fg;
      border_fg = ly c.blue;
      error_bg = ly c.bg;
      error_fg = "0x01${rm c.red}";
      cmatrix_fg = ly c.green;
      cmatrix_head_col = "0x01FFFFFF";
      colormix_col1 = ly c.black;
      colormix_col2 = ly c.blue;
      colormix_col3 = ly c.cyan;
      doom_top_color = ly c.red;
      doom_middle_color = ly c.yellow;
      doom_bottom_color = ly c.blue;
      gameoflife_fg = ly c.green;
    };

    environment.etc."hypr/colors.lua".text =
      "return "
      + lib.generators.toLua { } {
        active_border = "rgba(${rm c.blue}ff)";
        inactive_border = "rgba(00000000)";
        shadow = "rgba(${rm c.black}b3)";
        glass_tint = lib.fromHexString "${rm c.bg}a0";
      };

    environment.etc."quickshell/colors.json".text = builtins.toJSON {
      base = c.bg;
      fg = c.white;
      fgDim = c.brightBlack;
      hi = c.brightWhite;
      fontSans = config.stylix.fonts.sansSerif.name;
      fontMono = config.stylix.fonts.monospace.name;
      inherit (config.theming) accent;
      inherit (data.qs)
        good
        warn
        urgent
        ;
    };

    environment.etc."hypr/hyprpaper.conf".text = ''
      preload = ${toString data.wallpaper}

      wallpaper {
          monitor =
          path = ${toString data.wallpaper}
      }

      ipc = true
      splash = false
    '';

    environment.etc."hypr/hyprlock.conf".text =
      let
        rgba = hex: alpha: "rgba(${rm hex}${alpha})";
        sans = config.stylix.fonts.sansSerif.name;
        mono = config.stylix.fonts.monospace.name;
        margin = 96;
        at = x: y: "${toString x}, ${toString y}";
        user = lib.head (lib.attrValues (lib.filterAttrs (_: u: u.isNormalUser) config.users.users));
        firstName = lib.head (lib.splitString " " user.description);
        host = lib.toUpper config.networking.hostName;
        caps = text: "<span font_family='${mono}' letter_spacing='3072'>${text}</span>";
        # Empty command output renders as "Sample Text".
        script =
          name: text:
          pkgs.writeShellScript "hyprlock-${name}" ''
            PATH=${
              lib.makeBinPath [
                pkgs.coreutils
                pkgs.gnused
                pkgs.playerctl
              ]
            }
            ${text}
          '';
        clock = script "clock" ''
          echo "$(date +%-I:%M)<span font_family='${mono}' size='12%' letter_spacing='3072' rise='118pt' foreground='#${rm config.theming.accent}'> $(date +%p)</span>"
        '';
        dateline = script "date" ''
          echo "${caps "$(date '+%A  ·  %d %B' | tr a-z A-Z)"}"
        '';
        greeting = script "greeting" ''
          hour=$(date +%-H)
          if [ "$hour" -lt 5 ]; then g="Up late"
          elif [ "$hour" -lt 12 ]; then g="Good morning"
          elif [ "$hour" -lt 18 ]; then g="Good afternoon"
          else g="Good evening"; fi
          echo "$g, ${firstName}."
        '';
        media = script "media" ''
          status=$(playerctl status 2>/dev/null) || status=
          case "$status" in
            Playing) state="NOW PLAYING" ;;
            Paused) state="PAUSED" ;;
            *) echo " "; exit 0 ;;
          esac
          esc() { sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g'; }
          title=$(playerctl metadata title 2>/dev/null | esc)
          artist=$(playerctl metadata artist 2>/dev/null | esc)
          echo "<span size=\"70%\" foreground=\"#${rm config.theming.accent}\">${caps "$state"}</span>"
          echo "<span font_weight=\"500\">$title</span>"
          echo "<span foreground=\"#${rm c.brightBlack}\">$artist</span>"
        '';
        status = script "status" ''
          parts="${host}"
          for bat in /sys/class/power_supply/BAT*; do
            [ -r "$bat/capacity" ] || continue
            read -r pct <"$bat/capacity"
            read -r state <"$bat/status"
            case "$state" in
              Charging) parts="$parts  ·  CHARGING $pct%" ;;
              *) parts="$parts  ·  BATTERY $pct%" ;;
            esac
            break
          done
          echo "${caps "$parts"}"
        '';
        bottomLeft = {
          monitor = "";
          halign = "left";
          valign = "bottom";
        };
        bottomRight = {
          monitor = "";
          halign = "right";
          valign = "bottom";
          text_align = "right";
        };
      in
      inputs.home-manager.lib.hm.generators.toHyprconf {
        attrs = {
          general = {
            hide_cursor = true;
            ignore_empty_input = true;
          };

          animations = {
            enabled = true;
            bezier = "easeOut, 0.16, 1, 0.3, 1";
            animation = [
              "fadeIn, 1, 5, easeOut"
              "fadeOut, 1, 4, easeOut"
              "inputFieldColors, 1, 3, easeOut"
              "inputFieldDots, 1, 2, easeOut"
            ];
          };

          background = {
            monitor = "";
            path = toString data.wallpaper;
            blur_passes = 3;
            blur_size = 9;
            brightness = 0.45;
            contrast = 0.95;
            vibrancy = 0.2;
            noise = 0.015;
          };

          shape = bottomLeft // {
            size = at 28 3;
            rounding = 2;
            color = rgba config.theming.accent "ff";
            position = at margin 500;
          };

          label = [
            {
              monitor = "";
              text = "<span foreground='##${rm config.theming.accent}'>●</span>  ${caps "LOCKED"}";
              font_family = mono;
              font_size = 11;
              color = rgba c.white "99";
              halign = "left";
              valign = "top";
              position = at margin (-56);
            }
            (
              bottomLeft
              // {
                text = "cmd[update:60000] ${dateline}";
                font_family = mono;
                font_size = 12;
                color = rgba config.theming.accent "e6";
                position = at margin 460;
              }
            )
            (
              bottomLeft
              // {
                text = "cmd[update:1000] ${clock}";
                font_family = "${sans} Thin";
                font_size = 168;
                color = rgba c.white "f2";
                position = at (margin - 12) 200;
              }
            )
            (
              bottomLeft
              // {
                text = "cmd[update:60000] ${greeting}";
                font_family = "${sans} Light";
                font_size = 24;
                color = rgba c.white "b3";
                position = at margin 176;
              }
            )
            (
              bottomRight
              // {
                text = "cmd[update:2000] ${media}";
                font_family = sans;
                font_size = 17;
                color = rgba c.white "e6";
                position = at (-margin) 150;
              }
            )
            (
              bottomRight
              // {
                text = "cmd[update:30000] ${status}";
                font_family = mono;
                font_size = 11;
                color = rgba c.white "80";
                position = at (-margin) margin;
              }
            )
          ];

          input-field = bottomLeft // {
            size = at 380 52;
            position = at margin margin;
            rounding = 14;
            outline_thickness = 1;
            dots_center = false;
            dots_size = 0.22;
            dots_spacing = 0.5;
            fade_on_empty = false;
            font_family = sans;
            font_size = 14;
            placeholder_text = ''<span foreground="##${rm c.brightBlack}">${caps "PASSWORD"}</span>'';
            fail_text = "$FAIL";
            fail_timeout = 2500;
            inner_color = rgba c.white "0f";
            outer_color = rgba c.white "26";
            font_color = rgba c.white "f2";
            check_color = rgba config.theming.accent "cc";
            fail_color = rgba data.qs.urgent "e6";
            capslock_color = rgba data.qs.warn "cc";
          };
        };
      };
  };
}
