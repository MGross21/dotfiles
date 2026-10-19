{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop.bar.launcher;

  glyphNames = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/v3.5.1/glyphnames.json";
    hash = "sha256-0vpmFaOOtSdGLLcf8XqkSx1kU9Q37SY6uNW0WDk2aeg=";
  };

  entry = lib.types.submodule {
    options = {
      title = lib.mkOption {
        type = lib.types.str;
        description = "Row title, matched against the query.";
      };
      subtitle = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Secondary row text.";
      };
      value = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Substituted for `{}` in `exec`; null uses the title.";
      };
    };
  };

  provider = lib.types.submodule {
    options = {
      prefix = lib.mkOption {
        type = lib.types.str;
        example = "vm ";
        description = "Text that switches the launcher to this provider; include a trailing space for word prefixes.";
      };
      name = lib.mkOption {
        type = lib.types.str;
        description = "Label shown in the launcher's mode chips and footer.";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "application-x-executable-symbolic";
        description = "Icon theme name.";
      };
      placeholder = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Search field placeholder; empty uses `Search <name>`.";
      };
      entries = lib.mkOption {
        type = lib.types.listOf entry;
        default = [ ];
        description = "Static rows.";
      };
      list = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Optional argv printing extra rows, one per line as `title[\\tsubtitle[\\tvalue]]`.";
      };
      exec = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Argv run for the chosen row through `uwsm app`; `{}` becomes its value.";
      };
    };
  };
in
{
  options.desktop.bar.launcher.providers = lib.mkOption {
    type = lib.types.listOf provider;
    default = [ ];
    example = lib.literalExpression ''
      [
        {
          prefix = "vm ";
          name = "VMs";
          icon = "computer-symbolic";
          entries = [
            { title = "win11"; subtitle = "Windows 11"; }
            { title = "arch"; }
          ];
          exec = [ "virt-manager" "--connect" "qemu:///system" "--show-domain-console" "{}" ];
        }
      ]
    '';
    description = "Extra launcher modes, each selected by typing its prefix.";
  };

  config = lib.mkIf (config.desktop.enable && config.desktop.environment == "hyprland") {
    environment.etc = {
      "quickshell/launcher/emoji-test.txt".source =
        "${pkgs.unicode-emoji}/share/unicode/emoji/emoji-test.txt";
      "quickshell/launcher/glyphnames.json".source = glyphNames;
      "quickshell/launcher/providers.json".source =
        (pkgs.formats.json { }).generate "launcher-providers.json"
          cfg.providers;
    };

    systemd.user.services.quickshell.path = with pkgs; [
      fd
      file
      fzf
      libqalculate
      wl-clipboard
    ];
  };
}
