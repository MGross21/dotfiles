mode=${1:-toggle}
if [ "$mode" = toggle ]; then
  if hyprctl -j monitors all | jq -e 'any(.[]; .mirrorOf != "none")' >/dev/null; then
    mode=extend
  else
    mode=present
  fi
fi
case "$mode" in
  extend | present | laptop) exec shikanectl switch "$mode" ;;
  *)
    echo "usage: display-mode [toggle|extend|present|laptop]" >&2
    exit 1
    ;;
esac
