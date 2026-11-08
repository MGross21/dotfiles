# Reads the alert text on stdin and DMs it to $OWNER with the bot token from $DISCORD_ENV.
# shellcheck disable=SC1090
. "$DISCORD_ENV"
api=https://discord.com/api/v10
auth() { printf 'Authorization: Bot %s' "$DISCORD_BOT_TOKEN"; }
json=(-H 'Content-Type: application/json')
dm=$(jq -n --arg id "$OWNER" '{recipient_id: $id}' |
  curl -fsS -H @<(auth) "${json[@]}" -d @- "$api/users/@me/channels" | jq -r .id)
jq -Rs '{content: .}' |
  curl -fsS -o /dev/null -H @<(auth) "${json[@]}" -d @- "$api/channels/$dm/messages"
