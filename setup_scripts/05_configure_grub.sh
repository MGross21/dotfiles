#!/bin/bash
set -euo pipefail

echo "[*] Installing GRUB bootloader (UEFI)..."
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB



echo "[*] Patching /etc/default/grub..."

# Apply NVIDIA DRM modeset if NVIDIA drivers are installed
if pacman -Q nvidia-dkms &>/dev/null; then
    echo "[*] NVIDIA drivers detected. Adding DRM modeset..."
    sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia_drm.modeset=1 /' /etc/default/grub
fi

# Ensure os-prober is enabled for dual-boot detection
if grep -qE "^#?GRUB_DISABLE_OS_PROBER=true" /etc/default/grub; then
    sed -i 's/^#\?GRUB_DISABLE_OS_PROBER=true/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub
elif ! grep -q "^GRUB_DISABLE_OS_PROBER=" /etc/default/grub; then
    echo "GRUB_DISABLE_OS_PROBER=false" >> /etc/default/grub
    echo "[*] Enabled os-prober in GRUB config."
fi

# Install GRUB theme
echo "[*] Installing Elegant GRUB theme..."
git clone https://github.com/vinceliuice/Elegant-grub2-themes /tmp/elegant-grub
cd /tmp/elegant-grub
./install.sh -b -t mojave -i right
cd -
rm -rf /tmp/elegant-grub

# Rebuild GRUB configuration
echo "[*] Rebuilding GRUB configuration..."
grub-mkconfig -o /boot/grub/grub.cfg
