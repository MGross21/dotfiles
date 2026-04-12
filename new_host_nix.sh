#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./new_host_nix.sh [--host NAME] [--yes]

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

By default, prompts before writing files.
Use --yes to skip prompts.
EOF
}

confirm=true
host_arg=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      host_arg="${2:-}"
      shift 2
      ;;
    --yes|-y)
      confirm=false
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

resolve_host() {
  if [[ -n "$host_arg" ]]; then
    printf '%s\n' "$host_arg"
    return
  fi

  if command -v hostnamectl >/dev/null 2>&1; then
    local h
    h="$(hostnamectl --static 2>/dev/null || true)"
    if [[ -n "$h" ]]; then
      printf '%s\n' "$h"
      return
    fi
  fi

  if command -v hostname >/dev/null 2>&1; then
    local hs
    hs="$(hostname --short 2>/dev/null || true)"
    if [[ -n "$hs" ]]; then
      printf '%s\n' "$hs"
      return
    fi
  fi

  if [[ -n "${HOST:-}" ]]; then
    printf '%s\n' "$HOST"
    return
  fi

  hostname
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

if [[ "$confirm" == true ]]; then
  echo "About to create/update host: $host"
  echo "  Directory: $host_dir"
  read -r -p "Continue? [y/N] " answer
  if [[ ! "$answer" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
fi

mkdir -p "$host_dir"

if [[ -f "$default_file" ]]; then
  echo "default.nix already exists: $default_file"
else
  cat > "$default_file" <<EOF
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../configuration.nix
  ];

  networking.hostName = "$host";
}
EOF
  echo "Created: $default_file"
fi

if command -v nixos-generate-config >/dev/null 2>&1; then
  nixos-generate-config --show-hardware-config > "$hw_file"
  echo "Generated: $hw_file"
else
  if [[ -f "$hw_file" ]]; then
    echo "hardware-configuration.nix already exists: $hw_file"
  else
    cat > "$hw_file" <<'EOF'
# Placeholder file. Generate this on the target machine with:
# sudo nixos-generate-config --show-hardware-config > hosts/<host>/hardware-configuration.nix
{ ... }:
{
}
EOF
    echo "Created placeholder: $hw_file"
  fi
fi

if grep -q "nixosConfigurations\.${host}[[:space:]]*=" "$flake_file"; then
  echo "Flake entry already exists for host: $host"
else
  block=$(cat <<EOF
      nixosConfigurations.${host} = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit unstable;
        };
        modules = [
          ./hosts/${host}/default.nix
        ];
      };
EOF
)

  tmp_file="$(mktemp)"
  awk -v block="$block" '
    {
      if ($0 ~ /^      # End host entries$/ && inserted == 0) {
        print block
        inserted = 1
      }
      print
    }
    END {
      if (inserted == 0) {
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
echo "Build with: sudo nixos-rebuild switch --flake .#$host"
