{
  mactahoe-gtk,
  mactahoe-icons,
  nixpkgs-materia,
}:
final: prev: {
  materia-theme = nixpkgs-materia.legacyPackages.${prev.stdenv.hostPlatform.system}.materia-theme;

  kimun = final.callPackage ./kimun { };

  msi-perkeyrgb = final.callPackage ./msi-perkeyrgb { };

  papirus-red = final.callPackage ./papirus-red { };

  mactahoe-gtk-theme = final.callPackage ./mactahoe/gtk.nix { src = mactahoe-gtk; };
  mactahoe-icon-theme = final.callPackage ./mactahoe/icons.nix { src = mactahoe-icons; };
  mactahoe-cursor-theme = final.callPackage ./mactahoe/cursors.nix { src = mactahoe-icons; };
}
