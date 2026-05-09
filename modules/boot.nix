{ pkgs, ... }:
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
in
{
  boot.loader = {
    systemd-boot.enable = false;

    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      efiInstallAsRemovable = true;
      theme = sekiro-grub-theme;
    };

    efi.canTouchEfiVariables = false;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
}
