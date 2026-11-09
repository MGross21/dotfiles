{
  config,
  lib,
  pkgs,
  osConfig ? null,
  ...
}:
let
  inherit (config.dotfiles) dir homeConfiguration;
  switch =
    if osConfig == null then
      "nh home switch -c ${homeConfiguration}"
    else if pkgs.stdenv.hostPlatform.isDarwin then
      "nh darwin switch"
    else
      "nh os switch";
in
{
  options.dotfiles.homeConfiguration = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "Standalone `homeConfigurations` entry; null under NixOS or nix-darwin.";
  };

  config = {
    home.stateVersion = "25.11";

    programs.nh = {
      enable = true;
      flake = dir;
    };

    home.shellAliases = {
      update = "${switch} -u";
      nixrebuild = switch;
    }
    // lib.optionalAttrs (osConfig != null && pkgs.stdenv.hostPlatform.isLinux) {
      nixrollback = "nh os rollback";
      nixgens = "nh os info";
    };
  };
}
