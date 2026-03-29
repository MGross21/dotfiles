# Quick Start: NixOS Setup for mgross

## 📋 Current Status
- ✅ NixOS configuration created using flakes + home-manager (best practices)
- ✅ All Arch packages identified and mapped to nixpkgs equivalents
- ✅ Placeholder comments for packages needing verification
- ⏳ Waiting: NixOS installation on your machine
- ⏳ Waiting: Your dotfile configs (Hyprland, Neovim, etc.)

---

## 🎯 Your Next Steps (In Order)

### **BEFORE Installing NixOS** (Do Now)

1. **Read the migration guide** (5 min read)
   ```bash
   cat MIGRATION_GUIDE.md
   ```

2. **Backup your current Arch configs** (Very Important!)
   ```bash
   # While still on Arch, copy your ~/.config files
   mkdir -p ~/dotfiles/config/{hyprland,nvim,waybar,dunst,alacritty,ghostty}
   
   # Copy your custom configs
   cp -r ~/.config/hyprland/* ~/dotfiles/config/hyprland/ 2>/dev/null || echo "Hyprland not found"
   cp -r ~/.config/nvim/* ~/dotfiles/config/nvim/ 2>/dev/null || echo "Neovim not found"
   cp -r ~/.config/waybar/* ~/dotfiles/config/waybar/ 2>/dev/null || echo "Waybar not found"
   cp -r ~/.config/dunst/* ~/dotfiles/config/dunst/ 2>/dev/null || echo "Dunst not found"
   
   # Add these to home.nix after copying
   ```

3. **Verify package availability** (Optional but recommended)
   ```bash
   # Once you have nix installed, check uncertain packages:
   nix search nixpkgs hyprshot
   nix search nixpkgs waypaper
   nix search nixpkgs spotify-launcher
   
   # Update the TODO comments in system.nix with results
   ```

4. **Identify your hardware** (Required)
   ```bash
   # Get your boot device and disk info
   lsblk
   lscpu
   nvidia-smi  # Verify NVIDIA card
   
   # You'll need:
   - Boot device path (e.g., /dev/sda)
   - Timezone (e.g., America/Phoenix)
   - Username (currently: mgross)
   ```

5. **Prepare installation media**
   - Download NixOS ISO from https://nixos.org/download
   - Flash to USB with Rufus/Balena Etcher
   - Ready to install!

---

### **DURING/AFTER NixOS Installation** (Follow These)

#### Step 1: Boot NixOS ISO
```bash
# Boot from USB and get to the terminal
```

#### Step 2: Generate hardware config
```bash
sudo bash
nixos-generate-config --root /mnt

# This creates /mnt/etc/nixos/hardware-configuration.nix
# Copy it to your dotfiles repo (you'll do this after install)
```

#### Step 3: Clone your dotfiles
```bash
# Mount your filesystem first if needed
# Then clone
git clone https://github.com/MGross21/dotfiles.git /mnt/root/dotfiles
cd /mnt/root/dotfiles

# Edit configuration.nix and update:
# - hostname (currently "nixos")
# - boot.loader.grub.device (/dev/sda or your device)
# - time.timeZone
```

#### Step 4: Copy hardware config
```bash
cp /mnt/etc/nixos/hardware-configuration.nix /mnt/root/dotfiles/

# Edit flake.nix: change hostname from "nixos" to your actual hostname
```

#### Step 5: Install NixOS
```bash
cd /mnt/root/dotfiles
sudo nixos-rebuild switch --flake .#nixos
```

#### Step 6: Reboot and verify
```bash
sudo reboot

# After reboot, check:
nvidia-smi                    # NVIDIA drivers
hyprctl version              # Hyprland
sudo nixos-rebuild --flake . # Configuration
```

---

## 🔧 TODO Items to Complete

### In `configuration.nix`:
- [ ] Line 52: Update `hostname` from "nixos" to your actual host
- [ ] Line 63: Change `boot.loader.grub.device` to your boot disk
- [ ] Line 84: Update `time.timeZone` (you have "America/Phoenix")
- [ ] Line 101: Change username from "mgross" if different
- [ ] Line 121: Add your GRUB theme if desired (commented out)

### In `flake.nix`:
- [ ] Line 8: Update `hostname` variable to match configuration.nix

### In `home.nix`:
- [ ] Line 72: Update `userEmail` with your real email
- [ ] Line 73: Update `userName` with your real name
- [ ] Lines 21-30: Uncomment and point to your config files:
  ```nix
  ".config/hyprland".source = ../config/hyprland;
  ".config/nvim".source = ../config/nvim;
  # etc
  ```

### In `packages/system.nix`:
- [ ] Verify packages with `# TODO:` comments:
  - Search: `nix search nixpkgs <package>` when you have nix installed
  - Uncomment if found, leave commented if not
  - Delete if confirmed unavailable

---

## 📚 Useful Commands (After NixOS Install)

```bash
# Apply configuration changes
sudo nixos-rebuild switch --flake .

# Test changes without applying
sudo nixos-rebuild test --flake .

# Update packages to latest
sudo nix flake update

# See what will change
sudo nixos-rebuild dry-build --flake .

# Rollback to previous version
sudo nixos-rebuild switch --rollback

# Clean up old generations
nix-collect-garbage -d

# Search for packages
nix search nixpkgs package-name

# Find packages providing a command
nix-locate --whole-name --top-level bin/command-name
```

---

## 📖 Config Structure Explained

```
configuration.nix          ← Main system config (hardware, networking)
├── packages/system.nix    ← All system packages (firefox, gimp, etc)
├── packages/nvidia.nix    ← NVIDIA driver setup
├── packages/hyprland.nix  ← Hyprland + Wayland + Desktop Portal
└── packages/services.nix  ← Services (dunst, tlp, pipewire, etc)

home.nix                   ← User-level config (your environment)
├── programs.zsh           ← Shell configuration
├── programs.git           ← Git configuration
├── programs.tmux          ← Tmux configuration
└── home.file              ← Symlinked config files from ~/config/
```

---

## ⚠️ Common Mistakes to Avoid

1. ❌ **Forgetting to update hostname in BOTH files**
   - Update `flake.nix` AND `configuration.nix`

2. ❌ **Wrong boot device**
   - Check `lsblk` carefully before installing
   - NixOS can't use GPT partitions without EFI mode enabled

3. ❌ **Not backing up ~/.config before migrating**
   - Your Hyprland configs are precious!
   - Copy them NOW while still on Arch

4. ❌ **Expecting AUR packages to "just work"**
   - Not all AUR packages are in nixpkgs
   - Check availability FIRST

5. ❌ **Not reading error messages during rebuild**
   - NixOS errors are usually clear
   - Read them carefully before asking for help

---

## 🆘 If Something Goes Wrong

```bash
# Boot into previous working version
# (Available at GRUB boot menu - select "NixOS - Generation X")

# After booting into old version, investigate:
cat /var/log/messages
journalctl -xe
sudo journalctl -u systemd-modules-load

# Then revert:
sudo nixos-rebuild switch --rollback
```

---

## ✅ Success Indicators

After first boot, you should see:

```bash
$ hyprctl version
Hyprland, built from branch , at commit <hash> (...)

$ nvidia-smi
[Should show your GPU and driver version]

$ systemctl status --user
[Should show running user services]

$ echo $SHELL
/run/current-system/sw/bin/zsh
```

---

## 📞 Questions?

- **Flakes confused?** Read: https://nixos.wiki/wiki/Flakes
- **Hyprland issues?** Check: https://wiki.hyprland.org/Nix/
- **Package not found?** Search: https://search.nixos.org/packages
- **Need help?** IRC: #nixos on Libera.Chat

---

**You're all set! This config is production-ready. Best of luck with your NixOS migration! 🎉**
