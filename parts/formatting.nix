{ inputs, lib, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem.treefmt = {
    projectRootFile = "flake.nix";
    programs = {
      nixfmt.enable = true;
      deadnix.enable = true;
      statix = {
        enable = true;
        disabled-lints = (lib.importTOML ../statix.toml).disabled;
      };
      shellcheck.enable = true;
      ruff-check.enable = true;
      actionlint.enable = true;
    };
    settings.formatter = {
      deadnix.excludes = [ "hosts/*/hardware-configuration.nix" ];
      shellcheck.options = [
        "--shell"
        "bash"
      ];
    };
  };
}
