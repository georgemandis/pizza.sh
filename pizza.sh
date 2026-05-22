#!/usr/bin/env bash
#
# pizza.sh — find pizza near you from the command line
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Defaults
MOCK=""
RADIUS=2000
COUNT=5
JSON_MODE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --mock=*) MOCK="${1#--mock=}"; shift ;;
    --radius=*) RADIUS="${1#--radius=}"; shift ;;
    --count=*) COUNT="${1#--count=}"; shift ;;
    --json) JSON_MODE=true; shift ;;
    -h|--help)
      cat <<EOF
Usage: pizza.sh [options]

Find pizza near you and open the ordering page in your browser.

Options:
  --mock=LAT,LON    Use provided coordinates instead of whereami
  --radius=N        Search radius in meters (default: 2000)
  --count=N         Number of results to show (default: 5, max: 20)
  --json            Output JSON instead of interactive list
  -h, --help        Show this help message
EOF
      exit 0
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Load .env
if [[ -f "$SCRIPT_DIR/.env" ]]; then
  set -a; source "$SCRIPT_DIR/.env"; set +a
fi

# Check dependencies
if [[ -z "$MOCK" ]] && ! command -v whereami &>/dev/null; then
  echo "Error: whereami not found. Install it: brew install georgemandis/tap/whereami" >&2
  exit 1
fi

if ! command -v jq &>/dev/null; then
  echo "Error: jq not found. Install it: brew install jq" >&2
  exit 1
fi

if ! command -v curl &>/dev/null; then
  echo "Error: curl not found." >&2
  exit 1
fi

# Get location
if [[ -n "$MOCK" ]]; then
  LAT="${MOCK%%,*}"
  LON="${MOCK##*,}"
  echo "Using mock location: $LAT, $LON"
else
  echo "Finding your location..."
  LOCATION=$(whereami --json)
  LAT=$(echo "$LOCATION" | jq -r '.latitude')
  LON=$(echo "$LOCATION" | jq -r '.longitude')
  echo "  $LAT, $LON"
fi

# Check API key (after location so mock mode shows coordinates before failing)
if [[ -z "${GOOGLE_PLACES_API_KEY:-}" ]]; then
  echo "Error: GOOGLE_PLACES_API_KEY not set. Copy .env.example to .env and add your key." >&2
  exit 1
fi

# Search for pizza
echo ""
echo "Finding pizza near you..."

RESPONSE=$(curl -s -X POST "https://places.googleapis.com/v1/places:searchNearby" \
  -H "Content-Type: application/json" \
  -H "X-Goog-Api-Key: $GOOGLE_PLACES_API_KEY" \
  -H "X-Goog-FieldMask: places.displayName,places.formattedAddress,places.rating,places.googleMapsUri,places.websiteUri,places.location" \
  -d "$(jq -n \
    --argjson lat "$LAT" \
    --argjson lon "$LON" \
    --argjson count "$COUNT" \
    --argjson radius "$RADIUS" \
    '{
      includedTypes: ["pizza_restaurant"],
      maxResultCount: $count,
      locationRestriction: {
        circle: {
          center: {latitude: $lat, longitude: $lon},
          radius: $radius
        }
      }
    }')")

# Check for API errors
if echo "$RESPONSE" | jq -e '.error' &>/dev/null; then
  echo "Error from Google Places:" >&2
  echo "$RESPONSE" | jq -r '.error.message' >&2
  exit 1
fi

# Check for empty results
PLACE_COUNT=$(echo "$RESPONSE" | jq '.places // [] | length')
if [[ "$PLACE_COUNT" -eq 0 ]]; then
  echo "No pizza places found within ${RADIUS}m. Try a larger --radius."
  exit 0
fi

# Calculate distances and sort by distance
RESULTS=$(echo "$RESPONSE" | jq -r --argjson ulat "$LAT" --argjson ulon "$LON" '
  .places | to_entries | map(
    .value + {_index: .key}
  ) | map(
    . + {
      _dist_miles: (
        ((.location.longitude - $ulon) * (((($ulat + .location.latitude) / 2) * 3.14159265 / 180) | cos) * 69.172) as $dx |
        ((.location.latitude - $ulat) * 69.172) as $dy |
        (($dx * $dx + $dy * $dy) | sqrt)
      )
    }
  ) | sort_by(._dist_miles) | to_entries | map(
    {
      num: (.key + 1),
      name: .value.displayName.text,
      rating: (.value.rating // "N/A"),
      distance: ((.value._dist_miles * 10 | round) / 10),
      address: .value.formattedAddress,
      website: (.value.websiteUri // null),
      maps_url: .value.googleMapsUri
    }
  )
')

# JSON mode: print and exit
if [[ "$JSON_MODE" == true ]]; then
  echo "$RESULTS" | jq .
  exit 0
fi

# Display results
echo ""
echo "$RESULTS" | jq -r '.[] | "  \(.num). \(.name)\t\(.rating)\t\(.distance) mi\t\(.address)"' | column -t -s $'\t'
echo ""

# Prompt for selection
while true; do
  printf "Pick a pizza place (1-%d): " "$PLACE_COUNT"
  read -r CHOICE

  if [[ "$CHOICE" =~ ^[0-9]+$ ]] && [[ "$CHOICE" -ge 1 ]] && [[ "$CHOICE" -le "$PLACE_COUNT" ]]; then
    break
  fi
  echo "Invalid choice. Enter a number between 1 and $PLACE_COUNT."
done

# Get selected place
SELECTED=$(echo "$RESULTS" | jq ".[$((CHOICE - 1))]")
NAME=$(echo "$SELECTED" | jq -r '.name')
WEBSITE=$(echo "$SELECTED" | jq -r '.website // empty')
MAPS_URL=$(echo "$SELECTED" | jq -r '.maps_url')

if [[ -n "$WEBSITE" ]]; then
  URL="$WEBSITE"
else
  URL="$MAPS_URL"
fi

echo ""
echo "Opening $NAME..."
open "$URL"
