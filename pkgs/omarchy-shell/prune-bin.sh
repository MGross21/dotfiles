# Usage: prune-bin.sh <out> <keep>...
# Removes bin/ scripts unreachable from shell/, config/, default/ and <keep>.
set -euo pipefail

out=$1
shift
bin=$out/bin
name='omarchy-[a-z0-9-]+'

refs() {
  grep -rhoE "$name" "$@" | sort -u
  # Names built at runtime ("omarchy-agent-usage-$agent") keep every script sharing the prefix.
  grep -rhoE "$name-\\$" "$@" | sed 's/\$$//' | sort -u | while read -r prefix; do
    find "$bin" -maxdepth 1 -name "$prefix*" -printf '%f\n'
  done
}

declare -A kept
mapfile -t queue < <(printf '%s\n' "$@"; refs "$out/shell" "$out/config" "$out/default")
while ((${#queue[@]})); do
  n=${queue[-1]}
  unset 'queue[-1]'
  [[ -z ${kept[$n]:-} && -f $bin/$n ]] || continue
  kept[$n]=1
  mapfile -t -O "${#queue[@]}" queue < <(refs "$bin/$n")
done

for f in "$bin"/*; do
  [[ -n ${kept[${f##*/}]:-} ]] || rm "$f"
done
