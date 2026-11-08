dpms() {
  hyprctl dispatch "hl.dsp.dpms({ action = \"$1\" })" >/dev/null
}

on_ac() {
  for supply in /sys/class/power_supply/*; do
    [ "$(cat "$supply/type" 2>/dev/null)" = Mains ] &&
      [ "$(cat "$supply/online" 2>/dev/null)" = 1 ] && return 0
  done
  return 1
}

case "${1:-}" in
  lock)
    pidof hyprlock >/dev/null && exit 0
    paused=$(dunstctl is-paused 2>/dev/null || echo false)
    dunstctl set-paused true 2>/dev/null || true
    hyprlock -c /etc/hypr/hyprlock.conf || true
    dunstctl set-paused "$paused" 2>/dev/null || true
    ;;
  dim) brightnessctl -q -s set "$(($(brightnessctl get) * 3 / 10))" ;;
  undim) brightnessctl -q -r ;;
  dpms-off) pidof hyprlock >/dev/null && dpms off ;;
  dpms-on) dpms on ;;
  suspend)
    on_ac && exit 0
    systemd-inhibit --list --mode=block --no-legend | grep -qw sleep && exit 0
    systemctl suspend
    ;;
  *)
    echo "usage: idlectl lock|dim|undim|dpms-off|dpms-on|suspend" >&2
    exit 1
    ;;
esac
