{
  mactahoe-gtk,
  mactahoe-icons,
  nixpkgs-materia,
  omarchy,
}:
final: prev: {
  materia-theme = nixpkgs-materia.legacyPackages.${prev.stdenv.hostPlatform.system}.materia-theme;

  kimun = final.callPackage ./kimun { };

  msi-perkeyrgb = final.callPackage ./msi-perkeyrgb { };

  omarchy-shell-compat = final.callPackage ./omarchy-shell-compat { src = omarchy; };

  mactahoe-gtk-theme = final.callPackage ./mactahoe/gtk.nix { src = mactahoe-gtk; };
  mactahoe-icon-theme = final.callPackage ./mactahoe/icons.nix { src = mactahoe-icons; };
  mactahoe-cursor-theme = final.callPackage ./mactahoe/cursors.nix { src = mactahoe-icons; };
}
