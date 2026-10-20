{ ... }:
{
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      AppleShowAllExtensions = true;
      ApplePressAndHoldEnabled = false;
      KeyRepeat = 2;
      InitialKeyRepeat = 15;
      NSAutomaticSpellingCorrectionEnabled = false;
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticWindowAnimationsEnabled = false;
      # Ctrl+Cmd drag moves windows from anywhere.
      NSWindowShouldDragOnGesture = true;
    };

    dock = {
      autohide = true;
      show-recents = false;
      # AeroSpace workspaces break if macOS reorders Spaces.
      mru-spaces = false;
    };

    finder = {
      AppleShowAllFiles = true;
      FXPreferredViewStyle = "Nlsv";
      ShowPathbar = true;
      ShowStatusBar = true;
    };

    trackpad.Clicking = true;
    screencapture.location = "~/Pictures/screenshots";
  };
}
