{ inputs }:
{ config, lib, ... }:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";
    extraSpecialArgs = { inherit inputs; };
    # Shared options are set on the host and mirrored into every user.
    sharedModules =
      lib.filesystem.listFilesRecursive ../modules/shared
      ++ lib.filesystem.listFilesRecursive ../modules/home
      ++ [ { inherit (config) theming user dev; } ];
  };

  imports = lib.filesystem.listFilesRecursive ../modules/shared;
}
