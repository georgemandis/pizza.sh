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
