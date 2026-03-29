# Arch → NixOS Migration Guide

## What We've Created

A modern NixOS configuration using **flakes** and **home-manager** for reproducible, declarative system management.

### File Structure

```
/home/mgross/dotfiles/
├── flake.nix                  # Flake configuration (reproducible builds)
├── configuration.nix          # Main system configuration
├── home.nix                   # User-level home-manager config
├── hardware-configuration.nix # Generated during NixOS install (YOU CREATE THIS)
└── packages/
    ├── system.nix             # All system packages
    ├── nvidia.nix             # NVIDIA driver configuration
    ├── hyprland.nix           # Hyprland + Wayland setup
    └── services.nix           # System services (dunst, tlp, etc.)
```

---

## How Nix Configuration Works

### Key Concepts

1. **Declarative**: Instead of `pacman -S firefox`, you declare packages in config files
2. **Atomic Updates**: `nixos-rebuild switch` applies all changes or none
3. **Rollback**: Previous configurations are saved; you can boot into them
4. **Reproducible**: Same config = same system on any machine

### Common Commands (After NixOS Install)

```bash
# Apply configuration changes
sudo nixos-rebuild switch --flake .

# Update channels
sudo nix flake update

# See what changed
sudo nixos-rebuild dry-build --flake .

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Rebuild in background
sudo nix flake update && sudo nixos-rebuild switch --flake . &
```

---

## AUR Package Mapping

Checked nixpkgs for AUR equivalents. Results:

### ✅ **Found in nixpkgs** (Direct Equivalents)
- `waypaper` → `waypaper` ✓
- `spicetify-cli` → `spicetify-cli` ✓
- `visual-studio-code-bin` → `vscode` ✓
- `msi-perkeyrgb` → `openrgb` (similar, may need setup) ⚠️
- `android-sdk` → `android-tools` + `android-studio` (partial)

### ⚠️ **Partially Available / Complex**
- `hyprshot` → No direct equivalent; use `hyprland-workspaces` or `grimblast`
- `zoom` → Available but proprietary; verify license in nixpkgs
- `clipse` → CLI clipboard manager for Wayland (check availability)
- `gemini-cli` → May need custom package
- `eww` → Available but requires compilation flags

### 📦 **Already in system.nix**
- `ghc-copilot` → Use `nvim-copilot` plugin in home.nix
- oh-my-zsh → Configured in `home.nix` via home-manager

### 🔧 **Placeholders Added**
Commented out packages needing verification:
```nix
# TODO: Check nixpkgs
# - spotify-launcher
# - hyprshot
# - waypaper (ACTUALLY FOUND ✓)
# - msi-perkeyrgb
# - clipse
```

Search with:
```bash
nix search nixpkgs <package-name>
```

---

## Before Installing NixOS

### Prep Work

1. **Backup your Hyprland config**:
   ```bash
   # Copy your existing ~/.config files to dotfiles repo
   mkdir -p config/{hyprland,nvim,waybar,dunst}
   cp -r ~/.config/hyprland/* config/hyprland/
   cp -r ~/.config/nvim/* config/nvim/
   # ... etc for other configs
   ```

2. **Update home.nix with your configs**:
   ```nix
   home.file = {
     ".config/hyprland".source = ../config/hyprland;
     ".config/nvim".source = ../config/nvim;
   };
   ```

3. **Update TODOs in configuration**:
   - `hostname` in flake.nix
   - `boot.loader.grub.device`
   - `users.users.mgross` → Update username if different
   - `time.timeZone`
   - Git credentials in `home.nix`
   - Terminal theme preferences

### Installation Steps

1. **Get NixOS ISO**: Download from https://nixos.org/download
2. **Boot and run installer**:
   ```bash
   sudo -i
   nixos-generate-config --root /mnt
   # Edit /mnt/etc/nixos/configuration.nix if needed
   ```

3. **Generate `hardware-configuration.nix`**:
   ```bash
   sudo cp /etc/nixos/hardware-configuration.nix ~/dotfiles/
   ```

4. **Clone your dotfiles**:
   ```bash
   git clone <your-repo> ~/dotfiles
   cd ~/dotfiles
   ```

5. **Apply configuration**:
   ```bash
   sudo nixos-rebuild switch --flake .#nixos
   ```

---

## Migrating Your Configs

### Option A: Direct Copy (Recommended)
```bash
# Copy existing Arch configs (preserves all customizations)
cp -r ~/.config/hyprland ~/dotfiles/config/

# Then symlink in home.nix:
home.file.".config/hyprland".source = ../config/hyprland;
```

### Option B: Rebuild from Scratch
Use Hyprland's defaults (in `${pkgs.hyprland}/etc/hyprland/hyprland.conf`) and customize in NixOS:

```nix
# In packages/hyprland.nix
environment.etc."hyprland/hyprland.conf" = {
  text = ''
    # Your Hyprland config here
  '';
};
```

---

## Troubleshooting & Common Issues

### NVIDIA + Wayland/Hyprland Issues
```nix
# In packages/nvidia.nix, uncomment for your GPU type:
# hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;

# Ensure these are set:
environment.variables.LIBVA_DRIVER_NAME = "nvidia";
```

### Missing Package?
1. Search: `nix search nixpkgs package-name`
2. If not found, create overlays (advanced)
3. Use `buildFHSUserEnv` for unusual binaries

### Flake Errors
```bash
# Update and re-evaluate
nix flake update
nix flake check
```

---

## Next Steps

1. **PC Setup**:
   - [ ] Update hostname in flake.nix
   - [ ] Identify boot device (`lsblk`)
   - [ ] Note timezone
   - [ ] Have NixOS ISO ready

2. **Config Migration**:
   - [ ] Copy your ~/.config files
   - [ ] Update home.nix paths
   - [ ] Test package list (may need additions)

3. **Testing (Optional)**:
   - Use NixOS VM to test config before real install
   - `vmTools.runInLinuxVM`

4. **After Install**:
   - [ ] `sudo nixos-rebuild switch --flake .`
   - [ ] Set up Hyprland keybinds
   - [ ] Configure any proprietary software (zoom, spotify-launcher)
   - [ ] Test NVIDIA drivers with `nvidia-smi`

---

## Useful Resources

- **NixOS Manual**: https://nixos.org/manual/nixos/stable/
- **Nix Flakes**: https://nixos.wiki/wiki/Flakes
- **Home-Manager**: https://nix-community.github.io/home-manager/
- **Hyprland on NixOS**: https://wiki.hyprland.org/Nix/
- **Package Search**: https://search.nixos.org/packages

---

## Questions?

- Run `nix flake show` to see available outputs
- Check `configuration.nix` for all TODO comments
- Search packages: `nix search nixpkgs <name>`
- Test changes without rebooting: `sudo nixos-rebuild test --flake .`
