# NVIDIA Proprietary Driver Setup

This dotfiles configuration has been updated to use NVIDIA proprietary drivers instead of open-source drivers to potentially reduce desktop environment flickering.

## Changes Made

1. **Driver Package**: Changed from `nvidia-open-dkms` to `nvidia-dkms` in `packages/pacman.conf`
2. **Documentation**: Updated README.md to reflect proprietary driver usage

## GRUB Configuration

For optimal performance with proprietary NVIDIA drivers, consider adding these parameters to your GRUB configuration (`/etc/default/grub`):

```bash
GRUB_CMDLINE_LINUX_DEFAULT="... nvidia-drm.modeset=1 nvidia-drm.fbdev=1"
```

After modifying `/etc/default/grub`, regenerate the GRUB configuration:

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

## Hyprland Configuration

The Hyprland environment variables and settings in `.config/hypr/hyprland.conf` are already optimized for NVIDIA drivers:

- Hardware acceleration enabled
- NVIDIA-specific environment variables set
- Anti-flicker settings enabled
- Hardware cursor disabled (recommended for NVIDIA)

## Post-Installation Steps

After running the install script:

1. Reboot to load the proprietary drivers
2. Verify driver installation: `nvidia-smi`
3. Check Hyprland logs for any NVIDIA-related warnings
4. Test for reduced flickering in your desktop environment

## Troubleshooting

If you experience issues after switching to proprietary drivers:

1. Ensure no conflicting drivers are installed: `pacman -Qs nvidia`
2. Check kernel logs: `dmesg | grep nvidia`
3. Verify modprobe configuration: `lsmod | grep nvidia`

For more information, see the [Arch Linux NVIDIA Wiki](https://wiki.archlinux.org/title/NVIDIA).