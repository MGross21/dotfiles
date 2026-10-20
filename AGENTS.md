# AGENTS.md

## Repo Summary

This repository is a NixOS and nix-darwin dotfiles/setup repo.

- Layout: `hosts/`, `modules/nixos/`, `modules/darwin/`, portable home-manager in `modules/home/`, options shared by all in `modules/shared/`.
- The main NixOS host is `msi`, built from the flake output.

## Working Notes

- Prefer Nix-native configuration over shell string blocks whenever a module or option exists.
- Use native NixOS modules and options first; keep shell init blocks only for behavior that is not supported natively.
- When changing Nix files, format them with `nixfmt`.
