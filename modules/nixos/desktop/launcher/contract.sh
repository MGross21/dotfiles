# Usage: contract.sh snapshot <omarchy> | contract.sh check <omarchy> <plugin> <snapshot>
mode=$1
shell=$2/shell

fn() {
  local file=$1
  shift
  printf '## %s functions\n' "${file#"$shell"/}"
  for name in "$@"; do
    grep -E "^  function $name\\(" "$file" | sed -E 's/\s*\{\s*$//; s/^\s+//'
  done
}

decls() {
  printf '## %s declarations\n' "${1#"$shell"/}"
  grep -E '^\s*(required |readonly |default )*(property|function|signal) ' "$1" | sed -E 's/\s*\{\s*$//; s/^\s+//'
}

snapshot() {
  fn "$shell/services/PluginRegistry.qml" validateManifest entryPointUrl isEnabled parseScanOutput
  printf '## services/PluginRegistry.qml manifest\n'
  grep -E 'var required = ' "$shell/services/PluginRegistry.qml" | sed -E 's/^\s+//'
  printf '## services/PluginRegistry.qml scan\n'
  grep -E 'scan_(first|third)party|pluginsDir:' "$shell/services/PluginRegistry.qml"
  fn "$shell/shell.qml" summon hide isPluginOpen toggle deliverIfLoaded invokeIfLoaded computePanelEntries ensureService
  printf '## shell.qml injection\n'
  grep -E 'if \("(omarchyPath|shell|manifest)" in (item|inst|target)\)' "$shell/shell.qml" | sed -E 's/^\s+//'
  printf '## shell.qml ipc\n'
  grep -E 'function (summon|hide|toggle)\(id: string' "$shell/shell.qml" | sed -E 's/^\s+//'
  decls "$shell/services/PluginShellApi.qml"
  decls "$shell/Ui/OverlayWindow.qml"
  decls "$shell/Ui/BorderSurface.qml"
  printf '## Commons/ShellIpc.qml\n'
  cat "$shell/Commons/ShellIpc.qml"
  printf '## Commons/qmldir\n'
  cat "$shell/Commons/qmldir"
  printf '## Ui/qmldir\n'
  cat "$shell/Ui/qmldir"
}

if [[ $mode == snapshot ]]; then
  snapshot
  exit 0
fi

plugin=$3
expected=$4
failed=0

if ! diff -u --label committed --label omarchy "$expected" <(snapshot); then
  echo "launcher: omarchy plugin contract changed; review the diff above, retest the launcher, then refresh omarchy-contract.txt" >&2
  failed=1
fi

declared() {
  grep -qE "(property [A-Za-z]+|function) $2\b" "$1"
}

check() {
  local file=$1 pattern=$2
  local name
  while read -r name; do
    if ! declared "$file" "$name"; then
      echo "launcher: ${file#"$shell"/} no longer declares '$name'" >&2
      failed=1
    fi
  done < <(grep -rhoE "$pattern" "$plugin" --include='*.qml' | sed -E 's/.*\.//' | sort -u)
}

check "$shell/Commons/Color.qml" 'Commons\.Color\.(menu\.)?[a-z][A-Za-z]*'
check "$shell/Commons/Style.qml" 'Style\.(font\.|spacing\.)?[a-z][A-Za-z]*'
check "$shell/Commons/Border.qml" 'Border\.[a-z][A-Za-z]*'
check "$shell/Ui/BorderSurface.qml" 'body\.content[A-Za-z]*'

while read -r type; do
  if ! grep -qE "^(singleton )?$type " "$shell/Ui/qmldir" "$shell/Commons/qmldir"; then
    echo "launcher: omarchy no longer exports $type" >&2
    failed=1
  fi
done < <(grep -rhoE '^\s*(OverlayWindow|BorderSurface|ShellIpc) \{' "$plugin" --include='*.qml' | tr -d ' {' | sort -u)

manifest=$plugin/manifest.json
if ! grep -q "manifest.schemaVersion !== $(jq .schemaVersion "$manifest")" "$shell/services/PluginRegistry.qml"; then
  echo "launcher: omarchy rejects manifest schemaVersion $(jq .schemaVersion "$manifest")" >&2
  failed=1
fi
while read -r kind; do
  entry=$(jq -r --arg k "$kind" '.entryPoints[$k]' "$manifest")
  if [[ ! -f $plugin/$entry ]]; then
    echo "launcher: manifest entry point for $kind missing: $entry" >&2
    failed=1
  fi
done < <(jq -r '.kinds[]' "$manifest")

exit $failed
