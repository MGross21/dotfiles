{
  inputs,
  lib,
  self,
  ...
}:
{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
    "aarch64-darwin"
  ];

  flake.overlays.default = import ../pkgs {
    inherit (inputs)
      mactahoe-gtk
      mactahoe-icons
      nixpkgs-materia
      omarchy
      ;
  };

  perSystem =
    { pkgs, system, ... }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ self.overlays.default ];
      };

      formatter = pkgs.nixfmt-tree;

      packages = lib.mkMerge [
        (lib.mkIf (system == "x86_64-linux") {
          installer = self.nixosConfigurations.installer.config.system.build.isoImage;
          inherit (pkgs)
            kimun
            msi-perkeyrgb
            mactahoe-gtk-theme
            mactahoe-icon-theme
            mactahoe-cursor-theme
            ;
        })
        (lib.mkIf (system == "aarch64-linux") {
          installer = self.nixosConfigurations.installer-aarch64.config.system.build.isoImage;
        })
      ];
    };
}
