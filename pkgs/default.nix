{
  mactahoe-gtk,
  mactahoe-icons,
  nixpkgs-materia,
  omarchy,
}:
final: prev: {
  materia-theme = nixpkgs-materia.legacyPackages.${prev.stdenv.hostPlatform.system}.materia-theme;

  kimun = final.callPackage ./kimun { };

  kondo = final.callPackage ./kondo { };

  msi-perkeyrgb = final.callPackage ./msi-perkeyrgb { };

  xtool = final.callPackage ./xtool { };

  t3code = prev.t3code.override { enableCodex = false; };

  pixi = prev.pixi.overrideAttrs (old: {
    buildInputs = old.buildInputs ++ [
      final.aws-lc
      final.zstd
    ];
  });

  omarchy-shell-compat = final.callPackage ./omarchy-shell-compat { src = omarchy; };
  omarchy-shell = final.callPackage ./omarchy-shell { src = omarchy; };

  mactahoe-gtk-theme = final.callPackage ./mactahoe/gtk.nix { src = mactahoe-gtk; };
  mactahoe-icon-theme = final.callPackage ./mactahoe/icons.nix { src = mactahoe-icons; };
  mactahoe-cursor-theme = final.callPackage ./mactahoe/cursors.nix { src = mactahoe-icons; };
}
