{ config, lib, ... }:
lib.mkIf config.zramSwap.enable {
  boot.kernel.sysctl = {
    "vm.swappiness" = 180;
    "vm.page-cluster" = 0;
  };
}
