#!/bin/bash
set -euo pipefail

echo "=== Available Block Devices ==="
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,LABEL,UUID,MODEL,TRAN -e 7

echo
read -rp "Enter the dedicated disk to partition (e.g., /dev/sda): " DISK

# Confirm destructive action
echo "!!! WARNING: This will erase all data on $DISK !!!"
read -rp "Type 'yes' to continue: " confirm
if [[ "$confirm" != "yes" ]]; then
    echo "Aborted."
    exit 1
fi


echo "=== Disk Partitioning and Mounting for Arch Linux (Dedicated Drive) ==="

# Prompt for disk
read -rp "Enter the dedicated disk to partition (e.g., /dev/sda): " DISK

# Confirm destructive action
echo "!!! WARNING: This will erase all data on $DISK !!!"
read -rp "Type 'yes' to continue: " confirm
if [[ "$confirm" != "yes" ]]; then
    echo "Aborted."
    exit 1
fi

# Wipe and create GPT layout
echo "[*] Creating GPT partition table on $DISK..."
sgdisk --zap-all "$DISK"
parted "$DISK" --script mklabel gpt

# Recommended layout:
# - 512MB EFI
# - 8GB swap
# - Remaining space as root

parted "$DISK" --script mkpart ESP fat32 1MiB 513MiB
parted "$DISK" --script set 1 esp on
parted "$DISK" --script mkpart primary linux-swap 513MiB 8705MiB
parted "$DISK" --script mkpart primary ext4 8705MiB 100%

EFI="${DISK}1"
SWAP="${DISK}2"
ROOT="${DISK}3"

# Format
echo "[*] Formatting partitions..."
mkfs.fat -F32 "$EFI"
mkswap "$SWAP"
swapon "$SWAP"
mkfs.ext4 "$ROOT"

# Mount
echo "[*] Mounting partitions..."
mount "$ROOT" /mnt
mkdir -p /mnt/boot/efi
mount "$EFI" /mnt/boot/efi

echo "[*] Arch disk prepared and mounted successfully."