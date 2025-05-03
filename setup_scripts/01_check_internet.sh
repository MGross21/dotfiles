#!/bin/bash
set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib/common.sh" ]] && source "$SCRIPT_DIR/lib/common.sh"

section "Internet Connection Check"

echo "[*] Checking internet connection..."
if ping -c 1 archlinux.org &>/dev/null; then
    echo "[✓] Internet connection is active."
else
    echo "[-] No internet connection. Please connect and retry." >&2
    exit 1
fi
