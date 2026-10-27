{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.desktop.airdrop;
in
{
  imports = [ inputs.owly.nixosModules.default ];

  options.desktop.airdrop.enable = lib.mkEnableOption "AirDrop over AWDL via owly";

  config = lib.mkIf (config.desktop.enable && cfg.enable) {
    services.owly.enable = true;
  };
}
