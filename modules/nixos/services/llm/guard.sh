# env: LLM_PORT, IDLE_TICKS (minutes without a loaded model before suspending)
inhibitor=""
idle=0

busy() {
  systemd-inhibit --list --mode=block --no-legend | grep -qw sleep && return 0
  for session in $(loginctl list-sessions --no-legend | awk '{ print $1 }'); do
    [ "$(loginctl show-session "$session" -P Remote)" = yes ] && return 0
  done
  return 1
}

while sleep 60; do
  if curl -fsS --max-time 5 "http://127.0.0.1:$LLM_PORT/running" | jq -e '.running | length > 0' >/dev/null; then
    idle=0
    if [ -z "$inhibitor" ]; then
      systemd-inhibit --what=sleep --mode=block --who=llm --why="Serving tailnet LLM requests" sleep infinity &
      inhibitor=$!
    fi
    continue
  fi
  if [ -n "$inhibitor" ]; then
    kill "$inhibitor"
    inhibitor=""
  fi
  idle=$((idle + 1))
  if [ "$idle" -ge "$IDLE_TICKS" ]; then
    idle=0
    busy || systemctl suspend || true
  fi
done
