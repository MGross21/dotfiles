{
  inputs,
  lib,
  withSystem,
  ...
}:
let
  user = (lib.evalModules { modules = [ ../modules/shared/user.nix ]; }).config.user.name;

  mkHome =
    name: system:
    withSystem system (
      { pkgs, ... }:
      inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit inputs; };
        modules = [
          (inputs.import-tree ../modules/shared)
          (inputs.import-tree ../modules/home)
          (
            { config, ... }:
            {
              home = {
                username = config.user.name;
                homeDirectory = "${
                  if pkgs.stdenv.hostPlatform.isDarwin then "/Users" else "/home"
                }/${config.user.name}";
              };

              dotfiles.homeConfiguration = name;
              programs.home-manager.enable = true;
              targets.genericLinux.enable = pkgs.stdenv.hostPlatform.isLinux;
            }
          )
        ];
      }
    );
in
{
  flake.homeConfigurations =
    lib.mapAttrs'
      (host: system: rec {
        name = "${user}@${host}";
        value = mkHome name system;
      })
      {
        wsl = "x86_64-linux";
        wsl-arm = "aarch64-linux";
      };
}
