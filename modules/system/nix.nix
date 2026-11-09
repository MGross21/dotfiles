{ inputs, ... }:
{
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    accept-flake-config = true;
    warn-dirty = false;
  };

  nixpkgs = {
    config.allowUnfree = true;
    overlays = [ inputs.self.overlays.default ];
  };
}
