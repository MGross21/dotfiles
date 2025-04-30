#!/bin/bash
set -euo pipefail

echo "[*] Sourcing packages.conf..."
if [[ ! -f packages.conf ]]; then
    echo "[-] packages.conf not found. Exiting." >&2
    exit 1
else
    source packages.conf
fi

install_packages() {
    local -n packages=$1
    if [[ ${#packages[@]} -eq 0 ]]; then
        echo "No packages to install for group: $1"
        return
    fi
    echo "Installing packages for group: $1..."
    pacman -S --needed --noconfirm "${packages[@]}"
}

package_groups=(
    BASE
    GRAPHICS
    TERMINAL
    TERMINAL_UTILS
    HYPRLAND
    HYPRLAND_EXTRA
    FILE_MANAGER
    APPS
    AUDIO
    FONTS
    THEMING
)

for group in "${package_groups[@]}"; do
    if declare -p "$group" &>/dev/null; then
        install_packages "$group"
    else
        echo "Warning: Package group '$group' is not defined. Skipping."
    fi
done
