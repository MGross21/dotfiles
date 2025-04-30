#!/bin/bash
set -euo pipefail

echo "[*] Setting up system time and timezone..."

DEFAULT_TIMEZONE="America/Phoenix"

# Prompt user for timezone with default fallback
read -rp "Enter your timezone [Default: $DEFAULT_TIMEZONE]: " USER_TIMEZONE
USER_TIMEZONE="${USER_TIMEZONE:-$DEFAULT_TIMEZONE}"

# Validate timezone exists
if [[ ! -f "/usr/share/zoneinfo/$USER_TIMEZONE" ]]; then
    echo "[-] Invalid timezone: $USER_TIMEZONE" >&2
    exit 1
fi

ln -sf "/usr/share/zoneinfo/$USER_TIMEZONE" /etc/localtime
echo "[*] Timezone set to $USER_TIMEZONE"

# Sync hardware clock and enable NTP
hwclock --systohc
timedatectl set-ntp true
echo "[*] NTP time sync enabled"