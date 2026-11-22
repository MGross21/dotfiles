# AGENTS.md

## Repo Summary

This repository is a NixOS and nix-darwin dotfiles/setup repo.

- Layout: `hosts/`, `modules/nixos/`, `modules/darwin/`, NixOS+darwin common in `modules/system/`, portable home-manager in `modules/home/`, options shared by all in `modules/shared/`.
- The main NixOS host is `msi`, built from the flake output.

## Working Notes

- When changing Nix files, format them with `nixfmt`.
- Option and unit descriptions state only what the value is or does; no sentinel behavior, current-usage context, status tags, or usage hints. Note a sentinel's meaning as a short inline comment on the `default` line (`default = null; # unthemed`).
- Prefer interpolating existing variables or config values over hardcoding literals they already define (hostnames, users, paths, ports, names). When a name must also satisfy a constraint like sort order, enforce it with a fixed prefix around the variable, not by hardcoding the value.

## Nix Conventions

- Native options first (`powerManagement.*Commands`, `services.udev.extraRules`, module `settings`); custom units or text only when no option exists.
- Config files: attrsets rendered with `pkgs.formats.*`, `lib.generators.*` or `hm.generators.toHyprconf`; `''` text only where no generator fits (`extraConfig`-style options).
- Scripts: `pkgs.writeShellApplication`, not `writeShellScript`/`writeShellScriptBin`; bodies beyond a few lines live in a sibling `.sh` read with `builtins.readFile`.
- Script dependencies go in `runtimeInputs`, called by bare name, with `inheritPath = false` unless the script runs caller-supplied commands or host tools (`/run/wrappers`, session binaries).
- Nix values reach scripts through `runtimeEnv` as UPPERCASE variables; for lists, build the command in Nix and pass its path.
- Outside script bodies (`ExecStart`, wrapper targets, config values), reference binaries with `lib.getExe`/`lib.getExe'`, never `${pkg}/bin/x`.
- Wrap binaries with `makeWrapper`/`wrapProgram`, not a shell script.
- Repo tooling is a flake `apps` entry in `parts/`, not a loose script.
- Quote URLs; no bare `https://…` literals.
- No `rec { }`; use `let … in` (`finalAttrs` for derivations).
- No file- or module-level `with`; `with` scoped to one expression (`with pkgs; [ … ]`) is fine.
- No `<nixpkgs>` lookup paths; dependencies come from flake inputs.
- `import inputs.nixpkgs` always passes explicit `config` and `overlays`.
- `//` replaces whole top-level keys; when nested keys must merge, use `lib.recursiveUpdate` or module merging.
- Local sources use `lib.fileset.toSource` or `builtins.path` with a fixed `name`, never bare `src = ./.`.
