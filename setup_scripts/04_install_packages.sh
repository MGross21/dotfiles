#!/bin/bash
set -euo pipefail

declare -A config_files=(
    ["pacman.conf"]="pacman"
    ["yay.conf"]="yay"
    ["external.sh"]="external"
)

for config_file in "${!config_files[@]}"; do
    echo "[*] Sourcing $config_file..."
    if [[ ! -f $config_file ]]; then
        echo "[-] $config_file not found. Skipping." >&2
        continue
    fi

    if [[ $config_file == *.sh ]]; then
        source "$config_file"
    else
        source <(grep -v '^#' "$config_file")
    fi

    install_packages() {
        local -n packages=$1
        if [[ ${#packages[@]} -eq 0 ]]; then
            echo "No packages to install for group: $1"
            return
        fi
        echo "Installing packages for group: $1..."
        if [[ ${config_files[$config_file]} == "yay" ]]; then
            yay -S --needed --noconfirm "${packages[@]}"
        else
            pacman -S --needed --noconfirm "${packages[@]}"
        fi
    }

    package_groups=($(compgen -A variable | grep -E '^[A-Z_]+$'))

    for group in "${package_groups[@]}"; do
        if declare -p "$group" &>/dev/null; then
            install_packages "$group"
        else
            echo "Warning: Package group '$group' is not defined. Skipping."
        fi
    done
done
