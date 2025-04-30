#!/bin/bash
set -euo pipefail

echo "[*] Checking internet connection..."
if ! ping -c 1 archlinux.org &>/dev/null; then
    echo "[-] No internet connection. Please connect and retry." >&2
    exit 1
fi
