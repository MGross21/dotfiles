#!/bin/bash
set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/lib/common.sh" ]]; then
    source "$SCRIPT_DIR/lib/common.sh"
fi

section "Disk Partitioning"

info "Displaying available block devices..."
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,LABEL,MODEL,TRAN -e 7

# Add support for non-interactive mode
if [[ "$*" == *--non-interactive* ]]; then
    NON_INTERACTIVE=true
else
    NON_INTERACTIVE=false
fi

if $NON_INTERACTIVE; then
    DISK="/dev/sda"
else
    read -rp "Enter the dedicated disk to partition (e.g., /dev/sda) or press Ctrl+C to cancel: " DISK
fi

if [[ ! -e "$DISK" ]]; then
    error "Disk $DISK does not exist!"
    safe_exit
fi

if ! $NON_INTERACTIVE; then
    confirm_action "This will erase ALL data on $DISK. Are you sure?" || safe_exit "Disk partitioning cancelled by user."
fi

echo "[*] Creating GPT partition table on $DISK..."
sgdisk --zap-all $DISK
parted $DISK --script mklabel gpt

echo "[*] Creating partitions..."
parted $DISK --script mkpart ESP fat32 1MiB 513MiB
parted $DISK --script set 1 esp on
parted $DISK --script mkpart primary linux-swap 513MiB 8705MiB
parted $DISK --script mkpart primary ext4 8705MiB 100%

if [[ "$DISK" == *"nvme"* ]]; then
    EFI="${DISK}p1"
    SWAP="${DISK}p2"
    ROOT="${DISK}p3"
else
    EFI="${DISK}1"
    SWAP="${DISK}2"
    ROOT="${DISK}3"
fi

echo "[*] Formatting partitions..."
mkfs.fat -F32 $EFI
mkswap $SWAP
swapon $SWAP
mkfs.ext4 $ROOT

echo "[*] Mounting partitions..."
mount $ROOT /mnt
mkdir -p /mnt/boot/efi
mount $EFI /mnt/boot/efi

echo "[✓] Disk partitioning and mounting completed successfully!"