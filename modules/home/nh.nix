{
  config,
  lib,
  pkgs,
  osConfig ? null,
  ...
}:
let
  inherit (config.dotfiles) dir homeConfiguration;
  mode =
    if osConfig == null then
      "home"
    else if pkgs.stdenv.hostPlatform.isDarwin then
      "darwin"
    else
      "os";
  nh = cmd: "nh ${mode} ${cmd}" + lib.optionalString (mode == "home") " -c ${homeConfiguration}";
in
{
  options.dotfiles.homeConfiguration = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null; # NixOS or nix-darwin
    description = "Standalone `homeConfigurations` entry.";
  };

  config = {
    home.stateVersion = "25.11";

    programs.nh = {
      enable = true;
      flake = dir;
    };

    home.shellAliases = lib.mkMerge [
      {
        nixrebuild = nh "switch";
        update = "${nh "switch"} -u";
        nixbuild = nh "build";
        nixrepl = nh "repl";
      }
      (lib.mkIf (mode == "os") {
        nixtest = nh "test";
        nixrollback = nh "rollback";
        nixgens = nh "info";
      })
      (lib.mkIf (mode == "darwin") {
        nixrollback = "sudo darwin-rebuild --rollback";
        nixgens = "darwin-rebuild --list-generations";
      })
      (lib.mkIf (mode == "home") { nixgens = "home-manager generations"; })
    ];
  };
}
