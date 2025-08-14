# Debugging

A collection of strange gotchas and debug moments

## Login to Twitch

When logging in, I received an `"Incompatible Browser"` error, even though Firefox is supported.

**Fix:** The issue was with the [system clock](https://bbs.archlinux.org/viewtopic.php?id=289645).

```bash
sudo timedatectl set-timezone <time-zone>   # e.g., America/Phoenix
sudo timedatectl enable systemd-timesyncd --now
sudo timedatectl set-ntp true

# Verify status
timedatectl status
```

You should see output similar to:

```md
Time zone: <time-zone>
System clock synchronized: yes
NTP service: active
```

## System Dark Mode

Some websites use your system's dark mode setting.  
To control this on Linux:

1. Install a GTK settings manager
2. Use the GUI to set your preferred theme.

## Using OAuth to Login to GitHub via VSCode

If you encounter a `"Missing OS Keyring"` error:

1. Install the necessary keyring packages (e.g., `gnome-keyring`, `libsecret`).
2. Set the keyring password to match your user password.
3. Restart your system or re-source your shell profile.

To configure VSCode:

1. Open the Command Palette (`Ctrl+Shift+P`) and select **Preferences: Configure Runtime Arguments**.
2. Add `"password-store": "gnome-libsecret"` to your `argv.json` file.
3. Restart VSCode (`"Developer: Reload Window"` menu option will not work)

[Learn more about keyring options in VSCode](https://code.visualstudio.com/docs/configure/settings-sync#_recommended-configure-the-keyring-to-use-with-vs-code)

## Returning the Charge Light Functionality to MSI Laptops

If the charge LED stopped working after switching to Linux, try resetting the embedded controller (EC):

### EC Reset Steps

1. Power off the laptop completely.
2. Unplug the AC adapter.
3. Hold the power button for 30–60 seconds.
4. Plug the AC adapter back in.
5. Power on the laptop.

This often restores the charge LED functionality on MSI laptops.
