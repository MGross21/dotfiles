#!/bin/bash
set -euo pipefail

# Source common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[[ -f "$SCRIPT_DIR/lib/common.sh" ]] && source "$SCRIPT_DIR/lib/common.sh"

section "Finalize Installation"

info "Installation complete. Rebooting in 5 seconds. Press Ctrl+C to cancel."
for i in {5..1}; do
    echo -n "$i... "
    sleep 1
    echo
done

echo "[*] Rebooting system now..."
reboot
