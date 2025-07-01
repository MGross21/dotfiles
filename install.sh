#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PKG_DIR="$SCRIPT_DIR/packages"

# Helper functions
info()    { echo -e "\033[1;34m[INFO]\033[0m $*"; }
success() { echo -e "\033[1;32m[SUCCESS]\033[0m $*"; }
warning() { echo -e "\033[1;33m[WARN]\033[0m $*"; }
error()   { echo -e "\033[1;31m[ERROR]\033[0m $*"; exit 1; }

if [[ ! -d "$PKG_DIR" ]]; then
    error "Packages directory not found: $PKG_DIR"
fi

# Ensure yay is installed
ensure_yay() {
    if ! command -v yay &>/dev/null; then
        info "Installing yay (AUR helper)..."
        sudo pacman -S --needed --noconfirm git base-devel
        git clone https://aur.archlinux.org/yay.git /tmp/yay
        pushd /tmp/yay
        makepkg -si --noconfirm
        popd
        rm -rf /tmp/yay
    fi
}

# Install packages from a config file
install_from_config() {
    local config_file=$1
    local installer=$2
    info "Processing $config_file with $installer..."
    source <(grep -v '^#' "$config_file")
    local groups=( $(compgen -A variable | grep -E '^[A-Z_]+$') )
    for group in "${groups[@]}"; do
        declare -n pkgs=$group
        if [[ ${#pkgs[@]} -eq 0 ]]; then
            warning "No packages in $group from $config_file"
            continue
        fi
        info "Installing $group: ${pkgs[*]}"
        if [[ $installer == "pacman" ]]; then
            sudo pacman -S --needed --noconfirm "${pkgs[@]}"
        elif [[ $installer == "yay" ]]; then
            ensure_yay
            yay -S --needed --noconfirm "${pkgs[@]}"
        fi
    done
}

# Run external commands from external.conf
run_external() {
    local config_file=$1
    info "Processing $config_file for external commands..."
    source <(grep -v '^#' "$config_file")
    local groups=( $(compgen -A variable | grep -E '^[A-Z_]+$') )
    for group in "${groups[@]}"; do
        declare -n cmds=$group
        for cmd in "${!cmds[@]}"; do
            info "Running external: $cmd"
            eval "${cmds[$cmd]}"
        done
    done
}

# Main install steps
cd "$PKG_DIR"
[[ -f pacman.conf ]] && install_from_config pacman.conf pacman
[[ -f yay.conf ]] && install_from_config yay.conf yay
[[ -f external.conf ]] && run_external external.conf

success "All packages and external tools installed!"
