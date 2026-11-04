{ inputs, pkgs, ... }:
{
  imports = [ inputs.rex.homeManagerModules.default ];

  # The rex flake only packages Linux binaries.
  programs.rex.enable = pkgs.stdenv.hostPlatform.isLinux;
}
