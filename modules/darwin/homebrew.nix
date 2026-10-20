{ config, ... }:
{
  nix-homebrew = {
    enable = true;
    user = config.user.name;
    autoMigrate = true;
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      # Removes any cask or formula not declared here, including its app data.
      cleanup = "zap";
    };

    casks = [
      "ghostty"
      "firefox"
      "visual-studio-code"
      "zed"
      "raycast"
      "spotify"
      "discord"
      "localsend"
    ];
  };
}
