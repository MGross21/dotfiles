#!/bin/bash
set -euo pipefail

echo "Installation complete. Rebooting in 5 seconds. Press Ctrl+C to cancel."
for i in {5..1}; do
    echo -n "$i... "
    sleep 1
done
echo "Rebooting system now..."
reboot
