{
  config,
  inputs,
  ...
}:
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-bak";
    extraSpecialArgs = { inherit inputs; };
    # Shared options are set on the host and mirrored into every user.
    sharedModules = [
      (inputs.import-tree ./shared)
      (inputs.import-tree ./home)
      {
        inherit (config)
          theming
          user
          dev
          host
          ;
      }
    ];
  };

  imports = [ (inputs.import-tree ./shared) ];
}
