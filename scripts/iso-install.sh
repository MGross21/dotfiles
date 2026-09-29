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

# ── Dotfiles ─────────────────────────────────────────────────────────────────
until ping -c1 -W3 github.com &>/dev/null; do
  warn "No network — opening nmtui (quit it once connected)"
  sleep 2
  nmtui
done
ok "Network up"

if [[ -d "$DOTFILES_DIR/.git" ]]; then
  info "Updating dotfiles..."
  git -C "$DOTFILES_DIR" pull --ff-only || warn "Pull failed — using existing checkout"
else
  info "Cloning dotfiles..."
  git clone "$DOTFILES_REPO" "$DOTFILES_DIR" || die "Clone failed"
fi
ok "Dotfiles ready at $DOTFILES_DIR"

REPO_SCRIPT="$DOTFILES_DIR/scripts/iso-install.sh"
if [[ -z "${ISO_INSTALL_REEXEC:-}" && -f "$REPO_SCRIPT" ]] && ! cmp -s "$0" "$REPO_SCRIPT"; then
  info "Switching to the newer installer from the repo..."
  ISO_INSTALL_REEXEC=1 exec bash "$REPO_SCRIPT"
fi

host_eval() { nix eval --raw "$DOTFILES_DIR#nixosConfigurations.\"$HOST\".config.$1" "${@:2}"; }

# ── Host config selection ────────────────────────────────────────────────────
echo
info "Reading host configs from flake..."
mapfile -t HOSTS < <(nix eval --raw "$DOTFILES_DIR#nixosConfigurations" --apply \
  'c: builtins.concatStringsSep "\n" (builtins.filter (n: n != "installer") (builtins.attrNames c))')
(( ${#HOSTS[@]} )) || die "No nixosConfigurations found in $DOTFILES_DIR"
for i in "${!HOSTS[@]}"; do
  echo "  $((i+1))) ${HOSTS[$i]}"
done
echo

while true; do
  read -rp "$(echo -e "${BOLD}Select [1-${#HOSTS[@]}]: ${NC}")" CHOICE
  if [[ "$CHOICE" =~ ^[0-9]+$ ]] && (( CHOICE >= 1 && CHOICE <= ${#HOSTS[@]} )); then
    HOST="${HOSTS[$((CHOICE-1))]}"
    break
  fi
  warn "Invalid choice"
done

mapfile -t DISK_NAMES < <(host_eval disko.devices.disk --apply \
  'd: builtins.concatStringsSep "\n" (builtins.attrNames d)')
(( ${#DISK_NAMES[@]} == 1 )) \
  || die "$HOST must declare exactly one disko disk (found ${#DISK_NAMES[@]}); set storage.disko.enable = true"
DISK_NAME="${DISK_NAMES[0]}"

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

# ── Confirm ──────────────────────────────────────────────────────────────────
echo
echo -e "${BOLD}Summary:${NC}"
echo "  Disk:   $DISK (disko disk '$DISK_NAME')"
echo "  Host:   $HOST"
echo "  Flake:  $DOTFILES_DIR#$HOST"
echo
echo -e "${RED}${BOLD}WARNING: $DISK will be COMPLETELY AND IRREVERSIBLY ERASED.${NC}"
echo
read -rp "Type the disk path to confirm ($(basename "$DISK")): " CONFIRM
[[ "$CONFIRM" == "$(basename "$DISK")" ]] || die "Confirmation mismatch — aborted"

# ── Hardware config ──────────────────────────────────────────────────────────
HW="$DOTFILES_DIR/hosts/$HOST/hardware-configuration.nix"
if [[ ! -f "$HW" ]] || grep -q "Generated post-install on target" "$HW"; then
  info "Generating $HW from this machine..."
  nixos-generate-config --show-hardware-config --no-filesystems > "$HW" \
    || die "nixos-generate-config failed"
  git -C "$DOTFILES_DIR" add "$HW"
  ok "Hardware config generated (commit + push it after first boot)"
else
  ok "Using existing $HW"
fi

# ── Partition ────────────────────────────────────────────────────────────────
info "Partitioning + mounting $DISK..."
# shellcheck disable=SC2016
DISKO_SCRIPT=$(
  INSTALL_FLAKE="git+file://$DOTFILES_DIR" INSTALL_HOST="$HOST" \
  INSTALL_DISK_NAME="$DISK_NAME" INSTALL_DISK="$DISK" INSTALL_MNT="$MNT" \
  nix build --impure --no-link --print-out-paths --expr '
    let
      env = builtins.getEnv;
      sys = (builtins.getFlake (env "INSTALL_FLAKE")).nixosConfigurations.${env "INSTALL_HOST"};
    in
    (sys.extendModules {
      modules = [
        {
          disko.rootMountPoint = env "INSTALL_MNT";
          disko.devices.disk.${env "INSTALL_DISK_NAME"}.device = sys.pkgs.lib.mkForce (env "INSTALL_DISK");
        }
      ];
    }).config.system.build.diskoScript'
) || die "Failed to build disko script"
"$DISKO_SCRIPT" || die "disko partitioning failed"

# ── Swap top-up (low RAM) ────────────────────────────────────────────────────
RAM_GB=$(( $(awk '/MemTotal/{print $2}' /proc/meminfo) / 1024 / 1024 ))
info "Detected ${RAM_GB}G RAM"

SWAPFILE=""
cleanup_swap() { [[ -n "$SWAPFILE" ]] && { swapoff "$SWAPFILE" 2>/dev/null; rm -f "$SWAPFILE"; }; true; }
trap cleanup_swap EXIT

if (( RAM_GB < 16 )); then
  AVAIL_GB=$(( $(df --output=avail -BG "$MNT" | tail -1 | tr -dc '0-9') ))
  HAVE_GB=$(( $(awk '/SwapTotal/{print $2}' /proc/meminfo) / 1048576 ))
  CLOSURE_BYTES=$(nix path-info -S \
    "$DOTFILES_DIR#nixosConfigurations.\"$HOST\".config.system.build.toplevel" \
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

  if (( ADD_GB >= 1 )); then
    SWAPFILE="$MNT/.install-swap"
    info "Adding ${ADD_GB}G install swapfile ($SWAPFILE)..."
    if ! btrfs filesystem mkswapfile --size "${ADD_GB}g" "$SWAPFILE" 2>/dev/null; then
      rm -f "$SWAPFILE"
      touch "$SWAPFILE"
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
fi

# ── Install ──────────────────────────────────────────────────────────────────
export TMPDIR="$MNT/.install-tmp"
mkdir -p "$TMPDIR"

info "Installing NixOS ($HOST) into $MNT..."
nixos-install \
  --flake "$DOTFILES_DIR#$HOST" \
  --root "$MNT" \
  --no-root-passwd \
  || die "nixos-install failed"

rm -rf "$TMPDIR"
cleanup_swap
SWAPFILE=""

# ── Copy dotfiles to the new system ──────────────────────────────────────────
# shellcheck disable=SC2016
TARGET_USER=$(host_eval users.users --apply \
  'u: let n = builtins.filter (k: u.${k}.isNormalUser) (builtins.attrNames u); in if n == [ ] then "root" else builtins.head n')
TARGET_HOME=$(host_eval "users.users.\"$TARGET_USER\".home")
info "Copying dotfiles to $TARGET_HOME/dotfiles (owner $TARGET_USER)..."
mkdir -p "$MNT$TARGET_HOME"
cp -a "$DOTFILES_DIR" "$MNT$TARGET_HOME/dotfiles"
nixos-enter --root "$MNT" -c "chown -R '$TARGET_USER': '$TARGET_HOME/dotfiles'" \
  || warn "chown failed — fix with: sudo chown -R $TARGET_USER: $TARGET_HOME/dotfiles"
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
