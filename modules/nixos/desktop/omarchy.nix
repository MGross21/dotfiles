{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop.omarchy;
  c = config.theming.colors;
  commands = [
    "omarchy-shell"
    "omarchy-toggle-bar"
    "omarchy-toggle-notification-silencing"
  ];
  omarchy = pkgs.omarchy-shell.override {
    keepBins = commands;
    excludePlugins = [
      "clipboard"
      "dev-gallery"
      "dock"
      "emojis"
      "image-picker"
      "lock"
      "osd"
      "panels/disk-speedtest"
      "panels/dropbox"
      "panels/tailscale"
      "polkit"
      "reminders"
      "services/idle"
    ];
  };
  defaults = lib.importJSON "${omarchy}/config/omarchy/shell.json";
  wrapped = pkgs.runCommand "omarchy-shell-commands" { nativeBuildInputs = [ pkgs.makeWrapper ]; } (
    lib.concatMapStrings (name: ''
      makeWrapper ${lib.getExe' omarchy name} $out/bin/${name} \
        --set OMARCHY_PATH ${omarchy} \
        --prefix PATH : ${
          lib.makeBinPath [
            omarchy
            pkgs.quickshell
            pkgs.socat
          ]
        }
    '') commands
  );

  quietNotifications = pkgs.writeShellApplication {
    name = "omarchy-quiet-notifications";
    runtimeInputs = [ wrapped ];
    text = ''
      dnd=$(omarchy-shell -q notifications isDnd || true)
      [[ $dnd == on ]] || dnd=off
      omarchy-shell -q notifications setDnd on || true
      status=0
      "$@" || status=$?
      omarchy-shell -q notifications setDnd "$dnd" || true
      exit "$status"
    '';
  };

  plugin = lib.types.submodule {
    options = {
      source = lib.mkOption {
        type = lib.types.str;
        description = "Repository path of the plugin directory.";
      };
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = "Packages on the shell's PATH for the plugin.";
      };
      environment = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Environment variables of the shell for the plugin.";
      };
      stateDirectory = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null; # read-only
        description = "Directory under the user state directory the plugin may write.";
      };
      barSection = lib.mkOption {
        type = lib.types.nullOr (
          lib.types.enum [
            "left"
            "centerBegin"
            "center"
            "centerEnd"
            "right"
          ]
        );
        default = null; # not on the bar
        description = "Bar layout section the plugin's widget leads.";
      };
    };
  };
  plugins = lib.attrValues cfg.plugins;

  layout = defaults.bar.layout // {
    left = builtins.filter (w: w.id != "omarchy.menu") defaults.bar.layout.left;
    center = map (
      w: if w.id == "omarchy.clock" then w // { format = "ddd d h:mm AP"; } else w
    ) defaults.bar.layout.center;
  };
  barEntries =
    section:
    map (id: { inherit id; }) (
      lib.attrNames (lib.filterAttrs (_: p: p.barSection == section) cfg.plugins)
    );
in
{
  options.desktop.omarchy = {
    enable = lib.mkEnableOption "the Omarchy shell as bar and notification daemon";

    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = omarchy;
      description = "Omarchy shell package the bar runs.";
    };

    plugins = lib.mkOption {
      type = lib.types.attrsOf plugin;
      default = { };
      description = "Third-party plugins enabled in the Omarchy shell, keyed by manifest ID.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.desktop.enable && config.desktop.environment == "hyprland";
        message = "desktop.omarchy requires desktop.environment = \"hyprland\".";
      }
    ];

    environment.systemPackages = [ wrapped ];

    desktop.idle.lockWrappers = [ (lib.getExe quietNotifications) ];

    systemd.user.services.omarchy-bar = {
      description = "Omarchy shell bar";
      wantedBy = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      # uwsm resolves launched entries' executables against this PATH.
      path =
        with pkgs;
        [
          omarchy
          inotify-tools
          jq
          libnotify
          socat
          bash
          coreutils
          gawk
          gnused
          systemd
          networkmanager
          qrencode
          zbar
          ghostty
          uwsm
          "/run/current-system/sw"
        ]
        ++ lib.concatMap (p: p.packages) plugins
        ++ map (user: "/etc/profiles/per-user/${user}") (lib.attrNames config.home-manager.users);
      environment = {
        OMARCHY_PATH = "${omarchy}";
        QS_DISABLE_FILE_WATCHER = "1";
        # Scopes inherit this unit's sandbox; services are spawned fresh by the user manager.
        UWSM_APP_UNIT_TYPE = "service";
      }
      // lib.mergeAttrsList (map (p: p.environment) plugins);
      serviceConfig = {
        Type = "simple";
        ExecStart = "${lib.getExe' pkgs.quickshell "quickshell"} -n -p ${omarchy}/shell";
        Restart = "on-failure";
        RestartSec = "3";

        NoNewPrivileges = true;
        RestrictSUIDSGID = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        PrivateTmp = true;
        InaccessiblePaths = [
          "-%h/.gnupg"
          "-%h/.password-store"
          "-%h/.local/share/keyrings"
        ];
        ConfigurationDirectory = "omarchy";
        StateDirectory = [ "omarchy" ] ++ lib.concatMap (p: lib.toList p.stateDirectory) plugins;
        ReadWritePaths = [
          "%C"
          "%t"
        ];
        LockPersonality = true;
        RestrictRealtime = true;
        RestrictNamespaces = true;
        SystemCallArchitectures = "native";
      };
    };

    home-manager.sharedModules = [
      (hm: {
        home.shellAliases.barreload = "systemctl --user restart omarchy-bar";

        xdg.configFile =
          lib.mapAttrs' (
            id: p:
            lib.nameValuePair "omarchy/plugins/${id}" {
              source = hm.config.lib.dotfiles.fromRepo p.source;
              recursive = !hm.config.dotfiles.mutable;
            }
          ) cfg.plugins
          // {
            # Omarchy rewrites this file in place when the bar is edited; force reclaims it on switch.
            "omarchy/shell.json" = {
              force = true;
              source = (pkgs.formats.json { }).generate "shell.json" (
                lib.recursiveUpdate defaults {
                  bar.layout = lib.mapAttrs (section: widgets: barEntries section ++ widgets) layout;
                  plugins = (defaults.plugins or [ ]) ++ map (id: { inherit id; }) (lib.attrNames cfg.plugins);
                  # Must stay installed: the startup cover waits until it is ready or disabled.
                  disabledPlugins = [ "omarchy.background" ];
                }
              );
            };
          };

        xdg.stateFile."omarchy/current/theme/colors.toml".source =
          (pkgs.formats.toml { }).generate "colors.toml"
            {
              background = c.bg;
              foreground = c.fg;
              accent = config.theming.accent;
              muted = c.brightBlack;
              inherit (c) red;
            };
      })
    ];
  };
}
