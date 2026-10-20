{ inputs, overlay }:
{
  name,
  system,
}:
let
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
    overlays = [ overlay ];
  };
  inherit (pkgs) lib;
in
inputs.home-manager.lib.homeManagerConfiguration {
  inherit pkgs;
  extraSpecialArgs = { inherit inputs; };
  modules =
    lib.filesystem.listFilesRecursive ../modules/shared
    ++ lib.filesystem.listFilesRecursive ../modules/home
    ++ [
      (
        { config, ... }:
        {
          home = {
            username = config.user.name;
            homeDirectory = "${
              if pkgs.stdenv.hostPlatform.isDarwin then "/Users" else "/home"
            }/${config.user.name}";
            stateVersion = "25.11";
          };

          programs.home-manager.enable = true;
          targets.genericLinux.enable = pkgs.stdenv.hostPlatform.isLinux;

          programs.nh = {
            enable = true;
            flake = config.dotfiles.dir;
          };

          home.shellAliases = {
            update = "nix flake update --flake ${config.dotfiles.dir} && nh home switch ${config.dotfiles.dir} -c ${name}";
            hmswitch = "nh home switch ${config.dotfiles.dir} -c ${name}";
          };
        }
      )
    ];
}
