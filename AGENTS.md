# AGENTS.md

## Repo Summary
This repository is a mixed Arch Linux and NixOS dotfiles/setup repo.

- Arch Linux setup lives in `install.sh`, `scripts/`, and the package/theme bootstrap files.
- NixOS configuration lives in `flake.nix`, `configuration.nix`, `hosts/`, and `modules/`.
- The main NixOS host is `msi`, built from the flake output.

## Working Notes
- Prefer Nix-native configuration over shell string blocks whenever a module or option exists.
- Use native NixOS modules and options first; keep shell init blocks only for behavior that is not supported natively.
- When changing Nix files, format them with `nixfmt`.