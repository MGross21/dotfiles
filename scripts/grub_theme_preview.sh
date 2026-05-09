#!/usr/bin/env bash
set -euo pipefail

THEME_PATH=$(find /nix/store -maxdepth 1 -name "*sekiro-grub-theme*" -not -name "*.drv" | sort | tail -1)

if [[ -z "$THEME_PATH" ]]; then
  echo "Sekiro theme not in nix store. Run: nixos-rebuild switch --flake ~/dotfiles#msi"
  exit 1
fi

GRUB_CFG_SRC=$(sudo find /boot -name "grub.cfg" 2>/dev/null | head -1)

echo "Theme: $THEME_PATH"
echo "GRUB config: ${GRUB_CFG_SRC:-not found, using example}"

VENV=$(mktemp -d)
GRUB_CFG_TMP=$(mktemp --suffix=.cfg)
trap 'rm -rf "$VENV" "$GRUB_CFG_TMP"' EXIT

EXTRA_ARGS=""
if [[ -n "$GRUB_CFG_SRC" ]]; then
  sudo cp "$GRUB_CFG_SRC" "$GRUB_CFG_TMP"
  sudo chmod 644 "$GRUB_CFG_TMP"
  EXTRA_ARGS="--grub-cfg $GRUB_CFG_TMP"
fi

nix shell nixpkgs#grub2_efi nixpkgs#qemu nixpkgs#python3 nixpkgs#xorriso nixpkgs#OVMF --command bash -c "
  GRUB_LIB=\$(dirname \$(which grub-mkimage))/../lib/grub
  OVMF_IMAGE=\$(find /nix/store -maxdepth 4 -name 'OVMF_CODE.fd' 2>/dev/null | head -1)
  python3 -m venv '$VENV'
  '$VENV/bin/pip' install --quiet grub2-theme-preview
  G2TP_GRUB_LIB=\$GRUB_LIB G2TP_OVMF_IMAGE=\$OVMF_IMAGE \
    '$VENV/bin/grub2-theme-preview' '$THEME_PATH' --resolution 1920x1080 $EXTRA_ARGS
"
