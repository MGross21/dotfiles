#!/bin/bash

# Arch Linux Installation Script

set -euo pipefail

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Use sudo." >&2
    exit 1
fi

# Update system
echo "Updating system..."
if ! pacman -Syu --noconfirm; then
    echo "System update failed. Exiting." >&2
    exit 1
fi

# Check if packages.conf exists
if [[ ! -f packages.conf ]]; then
    echo "Error: packages.conf file not found. Exiting." >&2
    exit 1
fi

# Source the package variables
echo "Sourcing package variables..."
source packages.conf

# Function to install packages from an array
install_packages() {
    local -n packages=$1
    if [[ ${#packages[@]} -eq 0 ]]; then
        echo "No packages to install for group: $1"
        return
    fi
    echo "Installing packages for group: $1..."
    if ! pacman -S --needed --noconfirm "${packages[@]}"; then
        echo "Failed to install packages for group: $1. Exiting." >&2
        exit 1
    fi
}

# Define package groups
package_groups=(BASE HYPRLAND APPS AUDIO GRAPHICS HYPRLAND_EXTRA)

# Loop through each package group and install
for group in "${package_groups[@]}"; do
    if declare -p "$group" &>/dev/null; then
        install_packages "$group"
    else
        echo "Warning: Package group '$group' is not defined in packages.conf. Skipping."
    fi
done

# Rebuild GRUB configuration
echo "Rebuilding GRUB configuration..."
if ! grub-mkconfig -o /boot/grub/grub.cfg; then
    echo "Failed to rebuild GRUB configuration. Exiting." >&2
    exit 1
fi

# Prompt for reboot
read -p "System update and package installation complete. Reboot now? (y/N): " confirm
if [[ $confirm =~ ^[Yy]$ ]]; then
    echo "Rebooting system..."
    reboot
else
    echo "Reboot canceled. Please reboot manually to apply changes."
fi