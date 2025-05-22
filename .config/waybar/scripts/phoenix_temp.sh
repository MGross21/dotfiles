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
    1)  echo "" ;;   # Sunny
    2)  echo "" ;;   # Mostly Sunny
    3)  echo "" ;;   # Partly Sunny
    4)  echo "" ;;   # Intermittent Clouds
    5)  echo "" ;;   # Hazy Sunshine
    6)  echo "" ;;   # Mostly Cloudy
    7)  echo "" ;;   # Cloudy
    8)  echo "" ;;   # Dreary (Overcast)
    11) echo "" ;;   # Fog
    12) echo "" ;;   # Showers
    13) echo "" ;; # Mostly Cloudy w/ Showers
    14) echo "" ;; # Partly Sunny w/ Showers
    15) echo "" ;;   # T-Storms
    16) echo "" ;; # Mostly Cloudy w/ T-Storms
    17) echo "" ;; # Partly Sunny w/ T-Storms
    18) echo "" ;;   # Rain
    19) echo "" ;;   # Flurries
    20) echo "" ;; # Mostly Cloudy w/ Flurries
    21) echo "" ;; # Partly Sunny w/ Flurries
    22) echo "" ;;   # Snow
    23) echo "" ;; # Mostly Cloudy w/ Snow
    24) echo "" ;;   # Ice
    25) echo "" ;;   # Sleet
    26) echo "" ;;   # Freezing Rain
    29) echo "" ;;   # Rain and Snow
    30) echo "" ;;   # Hot
    31) echo "" ;;   # Cold
    32) echo "" ;;   # Windy
    33) echo "" ;;   # Clear (Night)
    34) echo "" ;;   # Mostly Clear (Night)
    35) echo "" ;;   # Partly Cloudy (Night)
    36) echo "" ;;   # Intermittent Clouds (Night)
    37) echo "" ;;   # Hazy Moonlight
    38) echo "" ;;   # Mostly Cloudy (Night)
    39) echo "" ;; # Partly Cloudy w/ Showers (Night)
    40) echo "" ;; # Mostly Cloudy w/ Showers (Night)
    41) echo "" ;; # Partly Cloudy w/ T-Storms (Night)
    42) echo "" ;; # Mostly Cloudy w/ T-Storms (Night)
    43) echo "" ;; # Mostly Cloudy w/ Flurries (Night)
    44) echo "" ;; # Mostly Cloudy w/ Snow (Night)
    *)  echo "" ;;   # Default / Unknown
  esac
}

ICON=$(get_icon "$ICON_CODE")
OUTPUT="${TEMP}°${UNIT} ${ICON}"

echo "$OUTPUT" | tee "$CACHE_FILE"
