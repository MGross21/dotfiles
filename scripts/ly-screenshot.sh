# Run via SSH while Ly login manager is on the local display.
# Reads /dev/fb0 directly — works from TTY or remote session.

OUTPUT="${1:-${NH_FLAKE:-$HOME/dotfiles}/Pictures/screenshots/ly_$(date +%Y%m%d_%H%M%S).png}"
mkdir -p "$(dirname "$OUTPUT")"

fbcat | ffmpeg -loglevel error -f ppm_pipe -i pipe:0 -frames:v 1 "$OUTPUT"

echo "Saved: $OUTPUT"
