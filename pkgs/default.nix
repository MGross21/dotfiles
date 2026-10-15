{
  mactahoe-gtk,
  mactahoe-icons,
  nixpkgs-materia,
  omarchy,
}:
final: prev: {
  # TODO: drop once nixos-unstable has NixOS/nixpkgs#573101 (3.8.0 can't read Go 1.27 export data)
  go-mockery = prev.go-mockery.overrideAttrs (
    finalAttrs: _: {
      version = "3.8.1";
      src = prev.fetchFromGitHub {
        owner = "vektra";
        repo = "mockery";
        tag = "v${finalAttrs.version}";
        hash = "sha256-HCbnifYWE/3CG85dt0FPWT9hLSQbgOXuOKTBJHO0S2U=";
      };
      vendorHash = "sha256-ksfAHdPdOd8ELS0CSBg+E7KPd5xX/uGeLPn9HiItjdI=";
    }
  );

  # TODO: drop once nixos-unstable has NixOS/nixpkgs#569702
  t3code = prev.t3code.overrideAttrs (old: {
    buildCommand = old.buildCommand + ''
      for program in "$out"/bin/*; do
        wrapProgram "$program" --prefix LD_LIBRARY_PATH : ${
          final.lib.makeLibraryPath [ final.stdenv.cc.cc.lib ]
        }
      done
    '';
  });

  materia-theme = nixpkgs-materia.legacyPackages.${prev.stdenv.hostPlatform.system}.materia-theme;

  kimun = final.callPackage ./kimun { };

  msi-perkeyrgb = final.callPackage ./msi-perkeyrgb { };

  omarchy-shell-compat = final.callPackage ./omarchy-shell-compat { src = omarchy; };

  mactahoe-gtk-theme = final.callPackage ./mactahoe/gtk.nix { src = mactahoe-gtk; };
  mactahoe-icon-theme = final.callPackage ./mactahoe/icons.nix { src = mactahoe-icons; };
  mactahoe-cursor-theme = final.callPackage ./mactahoe/cursors.nix { src = mactahoe-icons; };
}
