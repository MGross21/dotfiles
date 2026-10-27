#!/usr/bin/env bash
# Prints the nixosConfigurations whose host.role is "server".
set -euo pipefail

# shellcheck disable=SC2016
nix eval --raw .#nixosConfigurations --apply \
  'cfgs: toString (builtins.filter (n: (cfgs.${n}.config.host.role or null) == "server") (builtins.attrNames cfgs))'
echo
