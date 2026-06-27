{
  config,
  pkgs,
  lib,
  ...
}:
let
  sekiro-grub-theme = pkgs.stdenv.mkDerivation {
    pname = "sekiro-grub-theme";
    version = "unstable";
    src = pkgs.fetchFromGitHub {
      owner = "AbijithBalaji";
      repo = "sekiro_grub_theme";
      rev = "1b1e3840e9c378f4400bed2a8940f4ded364ba3f";
      sha256 = "sha256-uXwDjb0+ViQvdesG5gefC5zFAiFs/FfDfeI5t7vP+Qc=";
    };
    dontBuild = true;
    installPhase = ''
      mkdir -p $out
      cp -r Sekiro/. $out/
    '';
  };

  elegant-mojave-grub-theme = pkgs.stdenv.mkDerivation {
    pname = "elegant-mojave-grub-theme";
    version = "unstable";
    src = pkgs.fetchFromGitHub {
      owner = "vinceliuice";
      repo = "Elegant-grub2-themes";
      rev = "f8a8d41c8f306f8bdfae41db1a425cf0a2451477";
      sha256 = "sha256-4yPldMZ7g6FrGGvoF2oxvS6cGlM2X/ALX0mfq/Dax8c=";
    };
    nativeBuildInputs = [ pkgs.imagemagick ];
    buildPhase = ''
      tmpdir=$(mktemp -d)
      bash generate.sh -d "$tmpdir" -t mojave -i right
      mkdir -p "$out"
      cp -r "$tmpdir"/Elegant-mojave-window-right-dark/. "$out/"
    '';
    dontInstall = true;
  };

  grubTheme =
    if config.theming.name == "tokyo-night" then elegant-mojave-grub-theme else sekiro-grub-theme;
in
{
  boot.loader = {
    systemd-boot.enable = false;

    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      efiInstallAsRemovable = true;
      theme = grubTheme;
      copyKernels = true;
    };

    efi.canTouchEfiVariables = false;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
}
