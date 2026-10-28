{
  config,
  lib,
  ...
}:
let
  cfg = config.storage.disko;

  btrfs = {
    type = "btrfs";
    extraArgs = [ "-f" ];
    subvolumes =
      if cfg.ephemeral then
        {
          "@nix" = subvol "/nix";
          "@persist" = subvol "/persist";
        }
      else
        {
          "@" = subvol "/";
          "@home" = subvol "/home";
          "@nix" = subvol "/nix";
        };
  };

  subvol = mountpoint: {
    inherit mountpoint;
    mountOptions = [
      "compress=zstd"
      "noatime"
    ];
  };
in
{
  options.storage.disko = {
    enable = lib.mkEnableOption "the disko-managed disk layout";

    device = lib.mkOption {
      type = lib.types.str;
      default = "/dev/disk/by-id/PLACEHOLDER";
      description = "Whole disk that the layout is written to.";
    };

    ephemeral = lib.mkEnableOption "a tmpfs root with only /nix and /persist on disk";

    encrypt = lib.mkEnableOption "LUKS on the root partition, unlocked by passphrase at boot";
  };

  config = lib.mkIf cfg.enable {
    fileSystems."/persist" = lib.mkIf cfg.ephemeral { neededForBoot = true; };

    disko.devices = {
      nodev."/" = lib.mkIf cfg.ephemeral {
        fsType = "tmpfs";
        mountOptions = [
          "size=50%"
          "mode=755"
        ];
      };

      disk.main = {
        type = "disk";
        inherit (cfg) device;
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "fmask=0077"
                  "dmask=0077"
                ];
              };
            };
            swap = lib.mkIf (!cfg.ephemeral) {
              size = "8G";
              content = {
                type = "swap";
                randomEncryption = true;
              };
            };
            root = {
              size = "100%";
              content =
                if cfg.encrypt then
                  {
                    type = "luks";
                    name = "cryptroot";
                    content = btrfs;
                  }
                else
                  btrfs;
            };
          };
        };
      };
    };
  };
}
