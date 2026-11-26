# `hyprctl keyword` is rejected under the Lua parser, hence eval + hl.monitor().
if [ "$(cat /sys/class/power_supply/ADP1/online 2>/dev/null || echo 1)" = "1" ]; then
  mode=144.03
  sunshine=start
  tailnet=up
  pl1=45000000
  pl2=55000000
else
  mode=60.08
  sunshine=stop
  tailnet=down
  pl1=25000000
  pl2=35000000
fi

if [ "$TAILSCALE" = true ] && [ "$(id -u)" -eq 0 ]; then
  tailscale "$tailnet" || true
fi

rapl=/sys/class/powercap/intel-rapl:0
[ -w "$rapl/constraint_0_power_limit_uw" ] && echo "$pl1" > "$rapl/constraint_0_power_limit_uw"
[ -w "$rapl/constraint_1_power_limit_uw" ] && echo "$pl2" > "$rapl/constraint_1_power_limit_uw"
[ -w "$rapl/constraint_0_time_window_us" ] && echo 8000000 > "$rapl/constraint_0_time_window_us"

for dir in /run/user/*/hypr/*/; do
  [ -d "$dir" ] || continue
  uid=$(echo "$dir" | cut -d/ -f4)
  sig=$(basename "$dir")
  HYPRLAND_INSTANCE_SIGNATURE="$sig" XDG_RUNTIME_DIR="/run/user/$uid" \
    hyprctl eval \
      "hl.monitor({output='eDP-1',mode='1920x1080@$mode',position='0x0',scale=1.0})" || true

  if [ "$SUNSHINE" = true ]; then
    if [ "$(id -u)" -eq 0 ]; then
      systemctl --user --machine="$uid@" "$sunshine" sunshine.service || true
    else
      systemctl --user "$sunshine" sunshine.service || true
    fi
  fi
done
