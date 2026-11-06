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
      sha256 = hash;
    };

  system = fetchImage "system/lineage/waydroid_x86_64/lineage-20.0-20260927-GAPPS-waydroid_x86_64-system.zip" "1d79df0b17ab8f79d66fd3b5f94500cc02f1abe149cf8caa391380092ede6e2a";
  vendor = fetchImage "vendor/waydroid_x86_64/lineage-20.0-20261022-MAINLINE-waydroid_x86_64-vendor.zip" "91663c337013145208b6c533d7e1fa2a915a9864ddc8fc56966f40cd759648ac";

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
