#!/usr/bin/env bash
# Prints the flake attrs of every system/home configuration built for $1.
set -euo pipefail

system=$1

pick() {
  nix eval --raw ".#$1" --apply "cfgs: toString (map (n: \"$1.\\\"\${n}\\\".$2\")
    (builtins.filter (n: cfgs.\${n}.pkgs.stdenv.hostPlatform.system == \"$system\") (builtins.attrNames cfgs)))"
  echo
}

pick nixosConfigurations config.system.build.toplevel
pick darwinConfigurations system
pick homeConfigurations activationPackage
