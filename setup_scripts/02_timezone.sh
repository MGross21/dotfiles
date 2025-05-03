#!/bin/bash
set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib/common.sh" ]] && source "$SCRIPT_DIR/lib/common.sh"

section "Timezone Setup"

DEFAULT_TIMEZONE="America/Phoenix"

# Determine if running in non-interactive mode
NON_INTERACTIVE=false
[[ "$*" == *--non-interactive* ]] && NON_INTERACTIVE=true

# Get user timezone
if $NON_INTERACTIVE; then
    USER_TIMEZONE="$DEFAULT_TIMEZONE"
else
    read -rp "Enter your timezone [Default: $DEFAULT_TIMEZONE]: " USER_TIMEZONE
    USER_TIMEZONE="${USER_TIMEZONE:-$DEFAULT_TIMEZONE}"
fi

# Validate timezone
if [[ ! -f "/usr/share/zoneinfo/$USER_TIMEZONE" ]]; then
    error "Invalid timezone: $USER_TIMEZONE"
    safe_exit
fi

# Set timezone
echo "[*] Setting timezone to $USER_TIMEZONE..."
ln -sf "/usr/share/zoneinfo/$USER_TIMEZONE" /etc/localtime
hwclock --systohc
timedatectl set-ntp true

echo "[✓] Timezone set to $USER_TIMEZONE and NTP enabled."
