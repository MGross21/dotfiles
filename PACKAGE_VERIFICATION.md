# AUR Package Verification Checklist

This document tracks which AUR packages have been found/verified in nixpkgs.

**Last Updated**: 2026-02-21

## Package Status

### ✅ VERIFIED - Direct Equivalents Found

| AUR Package | nixpkgs Equivalent | Notes |
|-------------|-------------------|-------|
| waypaper | `waypaper` | Wayland wallpaper manager - found ✓ |
| spicetify-cli | `spicetify-cli` | Spotify customization tool - found ✓ |
| visual-studio-code-bin | `vscode` | VS Code official binaries - found ✓ |
| zoom | `zoom` | May require unfree packages enabled ⚠️ |
| android-sdk-cmdline-tools-latest | `android-tools` | Partial (command-line tools) |

### ⚠️ NEEDS VERIFICATION - Likely Available

| AUR Package | Status | How to Check |
|-------------|--------|-------------|
| hyprshot | ❓ | `nix search nixpkgs hyprshot` |
| spotify-launcher | ❓ | `nix search nixpkgs spotify-launcher` |
| msi-perkeyrgb | ❓ (Use openrgb) | `nix search nixpkgs openrgb` |
| gemini-cli | ❓ | `nix search nixpkgs gemini` |
| clipse | ❓ | `nix search nixpkgs clipse` |
| eww | ⚠️ Complex | In nixpkgs but requires build flags |

### ❌ LIKELY NOT IN NIXPKGS

- `msi-perkeyrgb` (too specific; use `openrgb` as alternative)

## How to Search

```bash
# Search for a package
nix search nixpkgs package-name

# Get full package info
nix search nixpkgs --json package-name | jq

# Check if package exists before adding
nix shell -I nixpkgs=channel:nixos-unstable --no-home -p package-name
```

## Adding Missing Packages

If a package isn't in nixpkgs:

1. **Use overlays** (wrap in NixOS configuration)
2. **Build manually** with `stdenv.mkDerivation`
3. **Use FHS environment** for binary compatibility
4. **Request addition** to nixpkgs repository

## Next Actions

- [ ] Run verification commands for "NEEDS VERIFICATION" packages
- [ ] Update this document with results
- [ ] Add custom package derivations if needed
- [ ] Update `packages/system.nix` with found packages

## Command Examples

```bash
# Install package temporarily to test
nix shell -I nixpkgs=channel:nixos-unstable -p hyprshot --command hyprshot --help

# Check package details
nix search --json nixpkgs 'hyprshot' | jq '.[] | {name, description}'

# Check if available in unstable (not just stable)
nix search http://nixos.org/channels/nixos-unstable hyprshot
```

---

**Note**: Some packages might have different names in nixpkgs. For example:
- `github-cli` is `githubnuclei` in nixpkgs
- `visual-studio-code-bin` might be under `vscode` or `vscode-fhs`

Always search before assuming a package isn't available!
