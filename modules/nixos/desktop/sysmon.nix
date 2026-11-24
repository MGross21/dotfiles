{
  config,
  lib,
  ...
}:
let
  id = "dotfiles.sysmon";
  busId = config.hardware.nvidia.prime.nvidiaBusId;
  hex = n: lib.fixedWidthString 2 "0" (lib.toLower (lib.toHexString (lib.toInt n)));
  pciDevice =
    bus:
    let
      p = lib.splitString ":" bus;
    in
    "/sys/bus/pci/devices/0000:${hex (lib.elemAt p 1)}:${hex (lib.elemAt p 2)}.${lib.elemAt p 3}";
in
{
  config = lib.mkIf config.desktop.omarchy.enable {
    desktop.omarchy.plugins.${id} = {
      source = ".config/omarchy/plugins/${id}";
      barSection = "right";
      environment =
        lib.optionalAttrs (lib.elem "nvidia" config.services.xserver.videoDrivers && busId != "")
          {
            DOTFILES_SYSMON_DGPU = pciDevice busId;
          };
    };
  };
}
