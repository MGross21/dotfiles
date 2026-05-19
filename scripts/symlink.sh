#!/usr/bin/env bash
set -euo pipefail

LINKS=(
.config/
.zshrc
.zprofile
.aliases
.paths
.exports
Pictures/
)

for link in "${LINKS[@]}"; do
    ln -svf "$HOME/dotfiles/$link" "$HOME"
done