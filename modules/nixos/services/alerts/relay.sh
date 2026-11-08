# Minimal HTTP/1.1 receiver for one socket-activated connection: answers 202, then pipes the body (capped at 4 KiB) to $RELAY_COMMAND.
length=0
while IFS= read -r line; do
  line=${line%$'\r'}
  [ -z "$line" ] && break
  case ${line,,} in content-length:*) length=${line#*: } ;; esac
done
case $length in '' | *[!0-9]*) length=0 ;; esac
[ "$length" -gt 4096 ] && length=4096
body=$(head -c "$length")
printf 'HTTP/1.1 202 Accepted\r\nContent-Length: 0\r\nConnection: close\r\n\r\n'
exec </dev/null >&2
printf '%s' "$body" | "$RELAY_COMMAND"
