#!/usr/bin/env bash
# Run via SSH while Ly login manager is on the local display.
# Reads /dev/fb0 directly — works from TTY or remote session.
set -euo pipefail

OUTPUT="${1:-$HOME/dotfiles/Pictures/screenshots/ly_$(date +%Y%m%d_%H%M%S).png}"
mkdir -p "$(dirname "$OUTPUT")"

if command -v fbcat &>/dev/null; then
  fbcat | ffmpeg -loglevel error -f ppm_pipe -i pipe:0 -frames:v 1 "$OUTPUT"
elif command -v fbgrab &>/dev/null; then
  fbgrab -c 32 "$OUTPUT"
else
  echo "No framebuffer capture tool found. Add pkgs.fbcat to environment.systemPackages and rebuild." >&2
  exit 1
fi

echo "Saved: $OUTPUT"
