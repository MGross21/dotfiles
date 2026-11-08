# Runs the openclaw CLI as the gateway user with its tokens and state.
if [ "$(id -un)" != "$OPENCLAW_USER" ]; then
  exec /run/wrappers/bin/sudo -u "$OPENCLAW_USER" "$0" "$@"
fi
set -a
# shellcheck disable=SC1090
. "$TOKEN_ENV"
# shellcheck disable=SC1090
if [ -r "$DISCORD_ENV" ]; then . "$DISCORD_ENV"; fi
set +a
exec openclaw "$@"
