#!/bin/bash
set -euo pipefail

# Source common library if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib/common.sh" ]] && source "$SCRIPT_DIR/lib/common.sh"

section "System Update"

echo "[*] Updating system packages..."
pacman -Syu --noconfirm

echo "[✓] System updated successfully."
