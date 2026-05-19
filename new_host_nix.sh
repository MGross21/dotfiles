#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./new_host_nix.sh [--host NAME] [--disk DEVICE] [--desktop] [--no-desktop] [--yes]

Creates:
  hosts/<host>/default.nix
  hosts/<host>/hardware-configuration.nix

Also adds a flake host entry in flake.nix if missing.

Host resolution order:
  1) --host NAME
  2) hostnamectl --static
  3) hostname --short
  4) $HOST
  5) hostname

Disk resolution order:
  1) --disk DEVICE  (e.g. /dev/nvme0n1, /dev/sda)
  2) interactive prompt

By default, prompts before writing files.
Use --yes to skip prompts.
EOF
}

confirm=true
host_arg=""
disk_arg=""
desktop_arg=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)       host_arg="${2:-}";   shift 2 ;;
    --disk)       disk_arg="${2:-}";   shift 2 ;;
    --desktop)    desktop_arg="yes";   shift   ;;
    --no-desktop) desktop_arg="no";    shift   ;;
    --yes|-y)     confirm=false;       shift   ;;
    --help|-h)    usage; exit 0               ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

resolve_host() {
  local h
  [[ -n "$host_arg" ]] && { echo "$host_arg"; return; }
  if command -v hostnamectl &>/dev/null; then
    h=$(hostnamectl --static 2>/dev/null) && [[ -n "$h" ]] && { echo "$h"; return; }
  fi
  if command -v hostname &>/dev/null; then
    h=$(hostname --short 2>/dev/null) && [[ -n "$h" ]] && { echo "$h"; return; }
  fi
  [[ -n "${HOST:-}" ]] && { echo "$HOST"; return; }
  hostname
}

resolve_disk() {
  if [[ -n "$disk_arg" ]]; then
    echo "$disk_arg"
    return
  fi
  echo "Available block devices:" >&2
  lsblk -d -o NAME,SIZE,MODEL 2>/dev/null | grep -v "^loop" >&2 || true
  echo >&2
  read -r -p "Target disk device (e.g. /dev/nvme0n1, /dev/sda): " disk_input
  echo "$disk_input"
}

host="$(resolve_host)"

if [[ ! "$host" =~ ^[a-zA-Z0-9._-]+$ ]]; then
  echo "Invalid host name: $host" >&2
  echo "Allowed characters: letters, digits, dot, underscore, dash" >&2
  exit 1
fi

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$repo_root"

flake_file="$repo_root/flake.nix"
if [[ ! -f "$flake_file" ]]; then
  echo "flake.nix not found in $repo_root" >&2
  exit 1
fi

host_dir="$repo_root/hosts/$host"
default_file="$host_dir/default.nix"
hw_file="$host_dir/hardware-configuration.nix"

disk="$(resolve_disk)"

if [[ ! "$disk" =~ ^/dev/ ]]; then
  echo "Invalid disk device: $disk (must start with /dev/)" >&2
  exit 1
fi

if [[ -z "$desktop_arg" ]]; then
  read -r -p "Include desktop (Hyprland, GUI apps)? [y/N] " desktop_answer
  [[ "$desktop_answer" =~ ^[Yy]$ ]] && desktop_arg="yes" || desktop_arg="no"
fi

if [[ "$confirm" == true ]]; then
  echo "About to create/update host: $host"
  echo "  Directory: $host_dir"
  echo "  Disk:      $disk"
  echo "  Desktop:   $desktop_arg"
  read -r -p "Continue? [y/N] " answer
  [[ "$answer" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
fi

mkdir -p "$host_dir"

if [[ -f "$default_file" ]]; then
  echo "default.nix already exists: $default_file"
else
  {
    cat <<EOF
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../configuration.nix
EOF
    [[ "$desktop_arg" == "yes" ]] && echo "    ../../modules/desktop.nix"
    cat <<EOF
    ../../modules/disko.nix
  ];

  networking.hostName = "$host";

  disko.devices.disk.main.device = "$disk";
}
EOF
  } > "$default_file"
  echo "Created: $default_file"
fi

if command -v nixos-generate-config &>/dev/null; then
  nixos-generate-config --show-hardware-config --no-filesystems > "$hw_file"
  echo "Generated: $hw_file"
elif [[ -f "$hw_file" ]]; then
  echo "hardware-configuration.nix already exists: $hw_file"
else
  cat > "$hw_file" <<'EOF'
# Generated post-install on target. Run:
# nixos-generate-config --show-hardware-config --no-filesystems
# and replace this file with the output.
{ config, lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
EOF
  echo "Created placeholder: $hw_file"
fi

if grep -q "nixosConfigurations\.${host}[[:space:]]*=" "$flake_file"; then
  echo "Flake entry already exists for host: $host"
else
  tmp_file="$(mktemp)"
  awk -v block="$(cat <<EOF
      nixosConfigurations.${host} = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit unstable;
        };
        modules = [
          stylix.nixosModules.stylix
          disko.nixosModules.disko
          ./hosts/${host}/default.nix
        ];
      };
EOF
)" '
    /^      # End host entries$/ && !inserted {
      print block
      inserted = 1
    }
    { print }
    END {
      if (!inserted) {
        print "Did not find host insertion marker in flake.nix" > "/dev/stderr"
        exit 2
      }
    }
  ' "$flake_file" > "$tmp_file"
  mv "$tmp_file" "$flake_file"
  echo "Added flake host entry: nixosConfigurations.$host"
fi

echo
echo "Done."
echo
echo "Deploy to new machine (target booted into NixOS minimal ISO):"
echo
echo "  # On target — enable SSH:"
echo "  systemctl start sshd && passwd"
echo
echo "  # From this machine:"
echo "  nix run github:nix-community/nixos-anywhere -- --flake path:$repo_root#$host root@<target-ip>"
echo
echo "Or rebuild locally: nh os switch $repo_root"
