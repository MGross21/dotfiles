# Usage: notify-failure UNIT  (env: ALERT_HOST, RELAY_URL)
unit=$1
logs=$(journalctl -u "$unit" -n 15 --no-pager -o cat | tail -c 1500)
# shellcheck disable=SC2016
printf '**%s**: `%s` failed\n```\n%s\n```' "$ALERT_HOST" "$unit" "$logs" |
  curl -fsS -m 20 --data-binary @- "$RELAY_URL"
