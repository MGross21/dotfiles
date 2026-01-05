#!/bin/bash
set -e

for script in ./scripts/*.sh; do
  [ -e "$script" ] || continue
  chmod +x "$script"
done

./scripts/packages_install.sh
./scripts/grub_theme_install.sh
./scripts/vscode_theme_install.sh
./scripts/symlink.sh
./scripts/system.sh