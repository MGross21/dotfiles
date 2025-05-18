#!/bin/zsh

source $HOME/.env

API_KEY=$ACCU_WEATHER
CITY="Phoenix"

[[ -z "$API_KEY" ]] && echo "No API key" && exit 1

# Get location key
LOCATION_KEY=$(curl -sf "http://dataservice.accuweather.com/locations/v1/cities/search?apikey=$API_KEY&q=$CITY" \
  | jq -r '.[0].Key?')

[[ -z "$LOCATION_KEY" ]] && echo "N/A" && exit 1

# Get weather data
WEATHER=$(curl -sf "http://dataservice.accuweather.com/forecasts/v1/hourly/1hour/$LOCATION_KEY?apikey=$API_KEY")

TEMP=$(echo "$WEATHER" | jq -r '.[0].Temperature.Value | round')
UNIT=$(echo "$WEATHER" | jq -r '.[0].Temperature.Unit')
ICON_CODE=$(echo "$WEATHER" | jq -r '.[0].WeatherIcon')

# Map AccuWeather icon codes to weather glyphs (Nerd Font / Font Awesome)
function get_icon() {
  case $1 in
    1|2) echo "" ;;       # Sunny
    3|4) echo "⛅" ;;       # Partly sunny
    5|6) echo "" ;;       # Cloudy
    7)   echo "☁️" ;;       # Overcast
    12|13|14|18|39|40) echo "🌧️" ;; # Rain
    15|16|17) echo "⛈️" ;; # Thunderstorm
    19|20|21|22) echo "❄️" ;; # Snow
    23|24) echo "🌫️" ;;     # Fog
    *) echo "🌡️" ;;         # Default
  esac
}

ICON=$(get_icon "$ICON_CODE")

# Output: e.g., "92°F ☀️"
echo "${TEMP}°${UNIT} ${ICON}"