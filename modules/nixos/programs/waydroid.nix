{
  config,
  lib,
  pkgs,
  ...
}:
let
  fetchImage =
    path: hash:
    pkgs.fetchurl {
      url = "mirror://sourceforge/waydroid/images/${path}";
      inherit hash;
    };

  system = fetchImage "system/lineage/waydroid_x86_64/lineage-20.0-20260927-GAPPS-waydroid_x86_64-system.zip" "sha256-HXnfCxerj3nWb9O1+UUAzALxq+FJz4yqOROACS7ebio=";
  vendor = fetchImage "vendor/waydroid_x86_64/lineage-20.0-20261022-MAINLINE-waydroid_x86_64-vendor.zip" "sha256-kWY8M3ATFFIItsUz1+H6KpFamGTdyPxWlm9AzXWWSKw=";

  images = pkgs.runCommand "waydroid-images" { nativeBuildInputs = [ pkgs.unzip ]; } ''
    mkdir $out
    unzip -d $out ${system} system.img
    unzip -d $out ${vendor} vendor.img
  '';
in
lib.mkIf config.virtualisation.waydroid.enable {
  # Kernel lacks legacy xtables (NETFILTER_XTABLES_LEGACY unset).
  virtualisation.waydroid.package = pkgs.waydroid.override { withNftables = true; };

  # Waydroid prefers images here over OTA downloads.
  environment.etc."waydroid-extra/images".source = images;

  systemd.services.waydroid-init = {
    description = "Initialize Waydroid";
    wantedBy = [ "waydroid-container.service" ];
    before = [ "waydroid-container.service" ];
    script = ''
      grep -qx 'images_path = /etc/waydroid-extra/images' /var/lib/waydroid/waydroid.cfg 2>/dev/null \
        || ${lib.getExe config.virtualisation.waydroid.package} init -f
    '';
    serviceConfig.Type = "oneshot";
  };
}
