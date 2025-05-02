#!/bin/bash

declare -A INSTALL=(
    [oh_my_zsh]="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"
    [zoxide]="https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh"
    [Spicetify]="https://raw.githubusercontent.com/spicetify/cli/main/install.sh"
)

for key in "${!INSTALL[@]}"; do
    echo "Installing $key..."
    curl -fsSL "${INSTALL[$key]}" | sh
done