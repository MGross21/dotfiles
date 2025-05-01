#!/bin/bash

INSTALL=(
    oh_my_zsh=sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    zoxide=curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
)

for item in "${INSTALL[@]}"; do
    key="${item%%=*}"
    cmd="${item#*=}"
    echo "Running $key..."
    eval "$cmd"
done