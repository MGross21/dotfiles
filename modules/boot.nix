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
      rev = "main";
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
      rev = "main";
      sha256 = "09yhkqc130nqi9pncxin8f00fkqv6rrk5dml0vm1lb37gic4pdkx";
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
