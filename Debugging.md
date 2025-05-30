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

If you see a `"Missing OS Keyring"` error:

1. Ensure required security/keyring packages are installed (e.g., `gnome-keyring`, `libsecret`).
2. Open the `Seahorse` app and create a `Login` keyring if it doesn't exist.
3. Set its password to match your user password.
4. Reboot or re-source your shell profile.
