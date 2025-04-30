#!/bin/bash
set -euo pipefail

echo "[*] Updating system..."
pacman -Syu --noconfirm

echo "[*] Setting system time..."
timedatectl set-ntp true