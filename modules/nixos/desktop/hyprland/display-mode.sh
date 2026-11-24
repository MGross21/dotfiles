status() {
  hyprctl -j monitors all | jq -r --arg int "$INTERNAL" --arg ext "$EXTERNAL" '
    [.[] | select(.name | test($ext))] as $outs
    | if ($outs | length) == 0 then "single"
      elif any(.[]; .mirrorOf != "none") then "present"
      elif any(.[]; .name == $int and .disabled) then "external"
      elif all($outs[]; .disabled) then "internal"
      else "extend" end'
}

mode=${1:-toggle}
if [ "$mode" = toggle ]; then
  if [ "$(status)" = present ]; then
    mode=extend
  else
    mode=present
  fi
fi
case "$mode" in
  status) status ;;
  extend | present | internal | external) exec shikanectl switch "$mode" ;;
  *)
    echo "usage: display-mode [toggle|status|extend|present|internal|external]" >&2
    exit 1
    ;;
esac
