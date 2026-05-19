#!/usr/bin/env bash
# Run via SSH while Ly login manager is on the local display.
# Reads /dev/fb0 directly — works from TTY or remote session.
set -euo pipefail

OUTPUT="${1:-$HOME/dotfiles/Pictures/screenshots/ly_$(date +%Y%m%d_%H%M%S).png}"
mkdir -p "$(dirname "$OUTPUT")"

if ! command -v fbgrab &>/dev/null; then
  echo "fbgrab missing. Add pkgs.fbgrab to environment.systemPackages and rebuild."
  exit 1
fi

fbgrab -c 32 "$OUTPUT"
echo "Saved: $OUTPUT"
