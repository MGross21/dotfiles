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

# ── Partition + install ──────────────────────────────────────────────────────
echo
RAM_GB=$(( $(awk '/MemTotal/{print $2}' /proc/meminfo) / 1024 / 1024 ))
info "Detected ${RAM_GB}G RAM"

if (( RAM_GB >= 16 )); then
  # Ample RAM: fast one-shot install into the live (RAM-backed) store.
  info "Partitioning $DISK and installing NixOS ($HOST) [disko-install]..."
  disko-install \
    --flake "$DOTFILES_DIR#$HOST" \
    --disk main "$DISK" \
    --write-efi-boot-entries \
    || die "disko-install failed"
else
  # Low RAM: partition first, back the RAM-backed /nix store with SSD swap, then
  # build — avoids "no space left on device" on /nix/.rw-store.
  warn "Low RAM (<16G) — disk-backed install; target swap active during build"

  info "Partitioning + mounting $DISK [disko]..."
  disko --mode disko \
    --flake "$DOTFILES_DIR#$HOST" \
    --disk main "$DISK" \
    || die "disko partitioning failed"

  # Target total swap ~1.5x the real closure (queried from cache, no build),
  # else a third of free disk. zram + disko's declared swap are already active,
  # so only top up the shortfall. Keep >=10G disk headroom; file removed before
  # reboot so it never ships on the installed system.
  AVAIL_GB=$(( $(df --output=avail -BG /mnt | tail -1 | tr -dc '0-9') ))
  HAVE_GB=$(( $(awk '/SwapTotal/{print $2}' /proc/meminfo) / 1048576 ))
  CLOSURE_BYTES=$(nix path-info -S \
    "$DOTFILES_DIR#nixosConfigurations.$HOST.config.system.build.toplevel" \
    2>/dev/null | awk 'END{print $NF}')
  if [[ "$CLOSURE_BYTES" =~ ^[0-9]+$ ]]; then
    CLOSURE_GB=$(( CLOSURE_BYTES / 1073741824 ))
    TARGET_GB=$(( CLOSURE_GB * 3 / 2 + 1 ))
    info "Closure ~${CLOSURE_GB}G → ${TARGET_GB}G target swap (${HAVE_GB}G already active, ${AVAIL_GB}G free)"
  else
    TARGET_GB=$(( AVAIL_GB / 3 ))
    warn "Could not size closure — targeting ${TARGET_GB}G swap"
  fi

  ADD_GB=$(( TARGET_GB - HAVE_GB ))
  MAX_BY_DISK=$(( AVAIL_GB - 10 ))
  (( ADD_GB > MAX_BY_DISK )) && ADD_GB=$MAX_BY_DISK

  SWAPFILE=""
  if (( ADD_GB >= 1 )); then
    SWAPFILE=/mnt/.install-swap
    info "Adding ${ADD_GB}G install swapfile ($SWAPFILE)..."
    if ! btrfs filesystem mkswapfile --size "${ADD_GB}g" "$SWAPFILE" 2>/dev/null; then
      # Fallback for older btrfs-progs: nodatacow file, no compression.
      truncate -s 0 "$SWAPFILE"
      chattr +C "$SWAPFILE" 2>/dev/null || true
      fallocate -l "${ADD_GB}G" "$SWAPFILE" || die "swapfile alloc failed"
      chmod 600 "$SWAPFILE"
      mkswap "$SWAPFILE" >/dev/null || die "mkswap failed"
    fi
    swapon "$SWAPFILE" || die "swapon failed"
  else
    info "Active swap (${HAVE_GB}G) already covers ${TARGET_GB}G target — no swapfile needed"
  fi
  swapon --show

  export TMPDIR=/mnt/tmp
  mkdir -p "$TMPDIR"

  info "Installing NixOS ($HOST) into /mnt [nixos-install]..."
  nixos-install \
    --flake "$DOTFILES_DIR#$HOST" \
    --root /mnt \
    --no-root-passwd \
    || { [[ -n "$SWAPFILE" ]] && swapoff "$SWAPFILE" 2>/dev/null; die "nixos-install failed"; }

  if [[ -n "$SWAPFILE" ]]; then
    info "Removing install swapfile..."
    swapoff "$SWAPFILE" 2>/dev/null || true
    rm -f "$SWAPFILE"
  fi
fi
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
