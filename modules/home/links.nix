{ config, lib, ... }:
let
  cfg = config.dotfiles;

  storeCopy =
    path:
    builtins.path {
      path = ../.. + "/${path}";
      name = "dotfiles-" + lib.strings.sanitizeDerivationName path;
    };
in
{
  options.dotfiles = {
    dir = lib.mkOption {
      type = lib.types.str;
      default = "${config.home.homeDirectory}/dotfiles";
      description = "Checkout of this repo; live links point into its working tree.";
    };

    mutable =
      lib.mkEnableOption "linking repo configs to the live checkout at `dir` instead of the store"
      // {
        default = config.host.role == "workstation";
      };
  };

  config = {
    # `path` is relative to the repo root.
    lib.dotfiles = {
      # Plain path: live checkout path when mutable, else a store copy.
      source = path: if cfg.mutable then "${cfg.dir}/${path}" else storeCopy path;
      # home.file / xdg.configFile source.
      fromRepo =
        path:
        if cfg.mutable then config.lib.file.mkOutOfStoreSymlink "${cfg.dir}/${path}" else storeCopy path;
    };

    # Removes old whole-dir links where the new generation has a real dir; links would otherwise be written through them.
    home.activation.unlinkLiveDirs = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      for t in ${
        lib.escapeShellArgs (map (f: f.target) (lib.filter (f: f.enable) (lib.attrValues config.home.file)))
      }; do
        while [[ $t != . ]]; do
          n="$newGenPath/home-files/$t"
          if [[ -d "$n" && ! -L "$n" && -L "$HOME/$t" && "$(readlink "$HOME/$t")" == /nix/store/*-home-manager-files/* ]]; then
            run rm "$HOME/$t"
          fi
          t=$(dirname "$t")
        done
      done
    '';

    home.activation.checkDotfilesDir = lib.mkIf cfg.mutable (
      lib.hm.dag.entryBefore [ "writeBoundary" ] ''
        if [[ ! -d ${lib.escapeShellArg cfg.dir}/.git ]]; then
          warnEcho "dotfiles.mutable: no checkout at ${cfg.dir}; linked configs are dangling. Run: git clone https://github.com/MGross21/dotfiles.git ${cfg.dir}"
        fi
      ''
    );
  };
}
