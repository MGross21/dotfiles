{
  description = "MGross21 dotfiles NixOS configuration";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://hyprland.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # hypr stack from nixpkgs (Hydra-cached, no compile)
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      disko,
      stylix,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      installerSystem = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          disko.nixosModules.disko
          (
            {
              pkgs,
              lib,
              config,
              ...
            }:
            {
              system.stateVersion = "26.05";

              services.openssh = {
                enable = true;
                settings.PermitRootLogin = "yes";
                settings.PermitEmptyPasswords = "yes";
              };
              boot.zfs.forceImportRoot = false;

              environment.systemPackages = with pkgs; [
                git
                curl
                vim
                parted
                gptfdisk
                (pkgs.writeShellScriptBin "nixos-install-interactive" (builtins.readFile ./scripts/iso-install.sh))
              ];

              documentation.enable = false;
              documentation.nixos.enable = false;
              i18n.supportedLocales = [ "en_US.UTF-8/UTF-8" ];
              hardware.enableAllFirmware = lib.mkForce false;
              hardware.enableRedistributableFirmware = true;

              image.fileName = "nixos_${config.system.stateVersion}_${pkgs.stdenv.hostPlatform.system}.iso";
              isoImage.squashfsCompression = "zstd -Xcompression-level 19";
              isoImage.includeSystemBuildDependencies = false;

              # Auto-launch installer when root logs in on console
              programs.bash.loginShellInit = ''
                if [[ "$(tty)" == /dev/tty1 ]] && [[ $EUID -eq 0 ]]; then
                  nixos-install-interactive
                fi
              '';

              systemd.services.clone-dotfiles = {
                description = "Clone dotfiles";
                wantedBy = [ "multi-user.target" ];
                after = [ "network-online.target" ];
                wants = [ "network-online.target" ];
                serviceConfig = {
                  Type = "oneshot";
                  RemainAfterExit = true;
                  ExecStart = "${pkgs.git}/bin/git clone https://github.com/MGross21/dotfiles /root/dotfiles";
                };
              };
            }
          )
        ];
      };
    in
    {
      formatter.${system} = pkgs.nixfmt;

      nixosConfigurations.installer = installerSystem;
      packages.${system}.installer = installerSystem.config.system.build.isoImage;

      # Host entries (managed by new_host_nix.sh)
      nixosConfigurations.msi = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          stylix.nixosModules.stylix
          disko.nixosModules.disko
          ./hosts/msi/default.nix
        ];
      };
      nixosConfigurations.dell = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          stylix.nixosModules.stylix
          disko.nixosModules.disko
          ./hosts/dell/default.nix
        ];
      };
      # End host entries
    };
}
