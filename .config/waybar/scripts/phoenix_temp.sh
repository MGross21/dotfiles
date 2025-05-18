#!/bin/zsh

source "$HOME/.env"

API_KEY=$ACCU_WEATHER
CITY="Phoenix"
CACHE_FILE="/tmp/weather_cache"
CACHE_TTL=1800  # 30 minutes

[[ -z "$API_KEY" ]] && echo "No API key" && exit 1

# Use cached data if valid
if [[ -f "$CACHE_FILE" && $(($(date +%s) - $(stat -c %Y "$CACHE_FILE"))) -lt $CACHE_TTL ]]; then
  cat "$CACHE_FILE"
  exit 0
fi

# Get location key
LOCATION_KEY=$(curl -sf "http://dataservice.accuweather.com/locations/v1/cities/search?apikey=$API_KEY&q=$CITY" \
  | jq -r '.[0].Key // empty')

[[ -z "$LOCATION_KEY" ]] && echo "N/A" && exit 1

# Get weather data
WEATHER=$(curl -sf "http://dataservice.accuweather.com/forecasts/v1/hourly/1hour/$LOCATION_KEY?apikey=$API_KEY")
[[ -z "$WEATHER" ]] && echo "N/A" && exit 1

TEMP=$(echo "$WEATHER" | jq -r '.[0].Temperature.Value // empty' | awk '{printf "%.0f", $1}')
UNIT=$(echo "$WEATHER" | jq -r '.[0].Temperature.Unit // "°"}')
ICON_CODE=$(echo "$WEATHER" | jq -r '.[0].WeatherIcon // 0')

# Map icon code to emoji/glyph
get_icon() {
  case $1 in
    1|2) echo "" ;;           # Sunny
    3|4) echo "⛅" ;;           # Partly sunny
    5|6) echo "" ;;           # Cloudy
    7)   echo "☁️" ;;          # Overcast
    12|13|14|18|39|40) echo "🌧️" ;; # Rain
    15|16|17) echo "⛈️" ;;     # Thunderstorm
    19|20|21|22) echo "❄️" ;;  # Snow
    23|24) echo "🌫️" ;;        # Fog
    *) echo "🌡️" ;;            # Default
  esac
}

ICON=$(get_icon "$ICON_CODE")
OUTPUT="${TEMP}°${UNIT} ${ICON}"

echo "$OUTPUT" | tee "$CACHE_FILE"