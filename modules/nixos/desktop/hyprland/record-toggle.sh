state="${XDG_RUNTIME_DIR:-/tmp}/record-toggle"

if [ -f "$state.pid" ] && kill -INT "$(cat "$state.pid")" 2>/dev/null; then
  hyprctl notify 5 3000 0 "Saved $(cat "$state.out")" >/dev/null
  exit 0
fi

case "${1:-screen}" in
  screen) target=(-w screen) ;;
  window) target=(-w portal) ;;
  region)
    workspaces=$(hyprctl -j monitors | jq '[.[].activeWorkspace.id]')
    geom=$(hyprctl -j clients |
      jq -r --argjson ws "$workspaces" \
        '.[] | select(.mapped and (.hidden | not)) | select(.workspace.id as $w | $ws | any(. == $w))
          | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' |
      slurp -f '%wx%h+%x+%y') || exit 0
    target=(-w region -region "$geom")
    ;;
  *)
    echo "usage: record-toggle [screen|window|region]" >&2
    exit 1
    ;;
esac

mkdir -p ~/Videos
out=~/Videos/"$(date +%Y%m%d_%H%M%S)".mp4
echo "$out" >"$state.out"

gpu-screen-recorder "${target[@]}" -f 60 -a default_output -o "$out" &
echo $! >"$state.pid"
status=0
wait $! || status=$?
rm -f "$state.pid"
if [ "$status" -ne 0 ]; then
  hyprctl notify 3 4000 0 "Recording failed (exit $status)" >/dev/null
fi
