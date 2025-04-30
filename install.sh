#!/bin/bash
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Run this as root. Use sudo." >&2
    exit 1
fi

echo "===> Arch Linux Modular Installer <==="

# List of steps
STEPS=($(ls setup_scripts | sed 's/\.sh$//' | sort))

for step in "${STEPS[@]}"; do
    script="setup_scripts/${step}.sh"
    if [[ -f "$script" ]]; then
        echo "--- Running $step ---"
        bash "$script"
    else
        echo "Warning: $script not found. Skipping."
    fi
done