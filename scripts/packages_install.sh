#!/bin/bash
set -euo pipefail



# ██████╗  █████╗  ██████╗███╗   ███╗ █████╗ ███╗   ██╗
# ██╔══██╗██╔══██╗██╔════╝████╗ ████║██╔══██╗████╗  ██║
# ██████╔╝███████║██║     ██╔████╔██║███████║██╔██╗ ██║
# ██╔═══╝ ██╔══██║██║     ██║╚██╔╝██║██╔══██║██║╚██╗██║
# ██║     ██║  ██║╚██████╗██║ ╚═╝ ██║██║  ██║██║ ╚████║
# ╚═╝     ╚═╝  ╚═╝ ╚═════╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝                                               


# Source the package arrays
source ../packages/pacman.conf

# Combine all arrays
ALL_PACKAGES=(
  "${BASE[@]}"
  "${SECURIITY[@]}"
  "${GRAPHICS[@]}"
  "${TERMINAL[@]}"
  "${TERMINAL_UTILS[@]}"
  "${HYPRLAND[@]}"
  "${HYPRLAND_EXTRA[@]}"
  "${FILE_MANAGER[@]}"
  "${APPS[@]}"
  "${APP_PLUGINS[@]}"
  "${LSP[@]}"
  "${AUDIO[@]}"
  "${FONTS[@]}"
  "${THEMING[@]}"
  "${DAEMONS[@]}"
)

# Install all packages
sudo pacman -Syu --needed "${ALL_PACKAGES[@]}"


# ██╗   ██╗ █████╗ ██╗   ██╗
# ╚██╗ ██╔╝██╔══██╗╚██╗ ██╔╝
#  ╚████╔╝ ███████║ ╚████╔╝ 
#   ╚██╔╝  ██╔══██║  ╚██╔╝  
#    ██║   ██║  ██║   ██║   
#    ╚═╝   ╚═╝  ╚═╝   ╚═╝   


source ../packages/aur.conf

if ! command -v yay &>/dev/null; then
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    pushd /tmp/yay
    makepkg -si --noconfirm
    popd
    rm -rf /tmp/yay
fi

# Install AUR packages
for pkg in "${APPS[@]}"; do
    yay -S --needed "$pkg"
done



# ██████╗  █████╗ ███████╗██╗  ██╗
# ██╔══██╗██╔══██╗██╔════╝██║  ██║
# ██████╔╝███████║███████╗███████║
# ██╔══██╗██╔══██║╚════██║██╔══██║
# ██████╔╝██║  ██║███████║██║  ██║
# ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝
                                


source ../packages/external.conf

# Run external commands
for cmd in "${!EXTERNAL[@]}"; do
    echo "Running external command: $cmd"
    eval "${EXTERNAL[$cmd]}"
done