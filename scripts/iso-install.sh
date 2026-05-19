#!/usr/bin/env bash
# NixOS interactive installer — runs on the live ISO
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

DOTFILES_DIR="/root/dotfiles"
DOTFILES_REPO="https://github.com/MGross21/dotfiles"
MNT="/mnt"

die()  { echo -e "${RED}ERROR: $*${NC}" >&2; exit 1; }
info() { echo -e "${CYAN}==> $*${NC}"; }
ok()   { echo -e "${GREEN} ✓  $*${NC}"; }
warn() { echo -e "${YELLOW}WARN: $*${NC}"; }

[[ $EUID -eq 0 ]] || die "Run as root"

echo -e "${BOLD}"
cat <<'EOF'
  ███╗   ██╗██╗██╗  ██╗ ██████╗ ███████╗
  ████╗  ██║██║╚██╗██╔╝██╔═══██╗██╔════╝
  ██╔██╗ ██║██║ ╚███╔╝ ██║   ██║███████╗
  ██║╚██╗██║██║ ██╔██╗ ██║   ██║╚════██║
  ██║ ╚████║██║██╔╝ ██╗╚██████╔╝███████║
  ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
               Interactive Installer
EOF
echo -e "${NC}"

# ── Wait for dotfiles ────────────────────────────────────────────────────────
if [[ ! -d "$DOTFILES_DIR/.git" ]]; then
  info "Dotfiles not found — cloning..."
  ping -c1 -W3 github.com &>/dev/null || die "No network. Connect and re-run."
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR" || die "Clone failed"
fi
ok "Dotfiles ready at $DOTFILES_DIR"

# ── Disk selection ───────────────────────────────────────────────────────────
echo
info "Available disks:"
echo
lsblk -d -o NAME,SIZE,MODEL,TRAN --noheadings | grep -v "^loop" | \
  awk '{printf "  /dev/%-10s %6s  %-30s %s\n", $1, $2, $3, $4}'
echo

while true; do
  read -rp "$(echo -e "${BOLD}Target disk (e.g. /dev/nvme0n1): ${NC}")" DISK
  [[ "$DISK" =~ ^/dev/ ]] || { warn "Must start with /dev/"; continue; }
  [[ -b "$DISK" ]]        || { warn "$DISK not a block device"; continue; }
  break
done

# ── Host config selection ────────────────────────────────────────────────────
echo
info "Available host configs:"
mapfile -t HOSTS < <(find "$DOTFILES_DIR/hosts" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
for i in "${!HOSTS[@]}"; do
  echo "  $((i+1))) ${HOSTS[$i]}"
done
echo "  $((${#HOSTS[@]}+1))) Enter new hostname"
echo

while true; do
  read -rp "$(echo -e "${BOLD}Select [1-$((${#HOSTS[@]}+1))]: ${NC}")" CHOICE
  if [[ "$CHOICE" =~ ^[0-9]+$ ]] && (( CHOICE >= 1 && CHOICE <= ${#HOSTS[@]} )); then
    HOST="${HOSTS[$((CHOICE-1))]}"
    break
  elif (( CHOICE == ${#HOSTS[@]}+1 )); then
    read -rp "$(echo -e "${BOLD}Hostname: ${NC}")" HOST
    [[ "$HOST" =~ ^[a-zA-Z0-9._-]+$ ]] || { warn "Invalid hostname"; continue; }
    warn "No host config found for '$HOST' — nixos-install will fail unless you create one first"
    break
  else
    warn "Invalid choice"
  fi
done

# ── Confirm ──────────────────────────────────────────────────────────────────
echo
echo -e "${BOLD}Summary:${NC}"
echo "  Disk:   $DISK"
echo "  Host:   $HOST"
echo "  Flake:  $DOTFILES_DIR#$HOST"
echo
echo -e "${RED}${BOLD}WARNING: $DISK will be COMPLETELY AND IRREVERSIBLY ERASED.${NC}"
echo
read -rp "Type the disk path to confirm ($(basename "$DISK")): " CONFIRM
[[ "$CONFIRM" == "$(basename "$DISK")" ]] || die "Confirmation mismatch — aborted"

# ── Partition with disko ─────────────────────────────────────────────────────
echo
info "Partitioning $DISK with disko..."
nix run github:nix-community/disko -- \
  --mode disko \
  --flake "$DOTFILES_DIR#$HOST" \
  || die "Disko failed"
ok "Disk partitioned and mounted at $MNT"

# ── Install ──────────────────────────────────────────────────────────────────
echo
info "Installing NixOS ($HOST)..."
nixos-install \
  --flake "$DOTFILES_DIR#$HOST" \
  --root "$MNT" \
  --no-root-passwd \
  || die "nixos-install failed"
ok "Installation complete"

# ── Done ─────────────────────────────────────────────────────────────────────
echo
echo -e "${GREEN}${BOLD}Installation successful!${NC}"
echo
read -rp "Reboot now? [Y/n] " REBOOT
if [[ ! "$REBOOT" =~ ^[Nn]$ ]]; then
  info "Rebooting..."
  reboot
fi
