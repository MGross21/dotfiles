{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  cfg = config.desktop.deskflow;

  # Fork adding RemoteDesktop and Clipboard portals.
  xdph-remote =
    (pkgs.callPackage "${inputs.xdph-remote}/nix/default.nix" {
      src = inputs.xdph-remote;
      version = "git-${inputs.xdph-remote.shortRev}";
    }).overrideAttrs
      (old: {
        buildInputs =
          old.buildInputs
          ++ (with pkgs; [
            cairo
            pango
            pixman
          ]);
      });

  deskflow = pkgs.symlinkJoin {
    name = "deskflow-${pkgs.deskflow.version}";
    paths = [ pkgs.deskflow ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/deskflow \
        --set QT_LOGGING_RULES "qt.qpa.wayland.textinput.warning=false"
    '';
  };
in
{
  options.desktop.deskflow.enable = lib.mkEnableOption "Deskflow input sharing";

  config = lib.mkIf (config.desktop.enable && cfg.enable) {
    environment.systemPackages = [ deskflow ];

    networking.firewall.allowedTCPPorts = [ 24800 ];

    programs.hyprland.portalPackage = lib.mkIf (config.desktop.environment == "hyprland") xdph-remote;
  };
}
