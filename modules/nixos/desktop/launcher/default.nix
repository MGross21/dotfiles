{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.desktop.launcher;
  id = "dotfiles.launcher";
  src = ../../../../.config/omarchy/plugins/${id};
  omarchy = config.desktop.omarchy.package;
  contract = lib.getExe (
    pkgs.writeShellApplication {
      name = "launcher-omarchy-contract";
      runtimeInputs = with pkgs; [
        coreutils
        diffutils
        gnugrep
        gnused
        jq
      ];
      text = builtins.readFile ./contract.sh;
    }
  );

  contractSnapshot = pkgs.runCommand "launcher-omarchy-contract.txt" { } ''
    ${contract} snapshot ${omarchy} > $out
  '';

  contractCheck = pkgs.runCommand "launcher-omarchy-contract-check" { } ''
    ${contract} check ${omarchy} ${src} ${./omarchy-contract.txt}
    touch $out
  '';

  data = pkgs.linkFarm "dotfiles-launcher-data" {
    "emoji-test.txt" = "${pkgs.unicode-emoji}/share/unicode/emoji/emoji-test.txt";
    "glyphnames.json" = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/v3.5.1/glyphnames.json";
      hash = "sha256-0vpmFaOOtSdGLLcf8XqkSx1kU9Q37SY6uNW0WDk2aeg=";
    };
    "providers.json" = (pkgs.formats.json { }).generate "launcher-providers.json" cfg.providers;
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
        default = null; # title
        description = "Substituted for `{}` in `exec`.";
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
        description = "Label shown for this mode.";
      };
      icon = lib.mkOption {
        type = lib.types.str;
        default = "application-x-executable-symbolic";
        description = "Icon theme name.";
      };
      placeholder = lib.mkOption {
        type = lib.types.str;
        default = ""; # `Search <name>`
        description = "Search field placeholder.";
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
        description = "Argv run for the chosen row; `{}` becomes its value.";
      };
    };
  };
in
{
  options.desktop.launcher.omarchyContract = lib.mkOption {
    type = lib.types.package;
    readOnly = true;
    default = contractSnapshot;
    description = "Snapshot of the Omarchy plugin interface the launcher is built against.";
  };

  options.desktop.launcher.providers = lib.mkOption {
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

  config = lib.mkIf config.desktop.omarchy.enable {
    desktop.omarchy.plugins.${id} = {
      source = ".config/omarchy/plugins/${id}";
      packages = with pkgs; [
        fd
        file
        fzf
        libqalculate
        wl-clipboard
      ];
      environment.DOTFILES_LAUNCHER_DATA = "${data}";
      stateDirectory = "dotfiles-launcher";
    };

    system.checks = [ contractCheck ];
  };
}
