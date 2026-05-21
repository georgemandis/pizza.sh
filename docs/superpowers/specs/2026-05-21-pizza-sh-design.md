# pizza.sh Design Spec

## Goal

A single bash script that finds pizza near you and opens the ordering page in your browser. Showcases [whereami](https://github.com/georgemandis/whereami) in a fun, composable, unix-y way.

## Architecture

`pizza.sh` is one executable bash script. It calls `whereami --json` for coordinates, hits Google Places Nearby Search for pizza restaurants, displays an interactive numbered list, and opens the user's pick in the default browser.

No subcommands, no build step, no package manager. One script, one API key.

## Flow

```
User runs ./pizza.sh
  → whereami --json → { latitude, longitude }
  → curl Google Places searchNearby (includedTypes: pizza_restaurant)
  → jq parses response → calculate distance → sort by distance
  → Display numbered list: name, rating, distance, address
  → User enters a number
  → open $URL (websiteUri if available, else googleMapsUri)
```

## Dependencies

- `whereami` — native OS location (macOS/Linux/Windows). Already installable via Homebrew.
- `curl` — HTTP requests (system default on macOS/Linux)
- `jq` — JSON parsing
- Google Places API key (stored in `.env`)

## Files

```
pizza.sh          # The entire script (executable, #!/usr/bin/env bash)
.env              # GOOGLE_PLACES_API_KEY=...
.env.example      # Template with placeholder
.gitignore        # .env
README.md         # Usage, setup, blog post context
```

## CLI Interface

```
Usage: pizza.sh [options]

Options:
  --mock=LAT,LON    Use provided coordinates instead of whereami
  --radius=N        Search radius in meters (default: 2000)
  --count=N         Number of results to show (default: 5)
  --json            Output JSON instead of interactive list
  -h, --help        Show help
```

### Flag details

- `--mock=LAT,LON`: Skips the `whereami` call entirely. Uses the provided coordinates. Mirrors whereami's own `--mock` flag. Essential for demos, blog post readers who don't have whereami installed, and testing.
- `--radius=N`: Passed directly to Google Places `locationRestriction.circle.radius`. Default 2000 meters (~1.2 miles).
- `--count=N`: Passed to Google Places `maxResultCount`. Default 5. Max 20 (Google's limit).
- `--json`: Outputs the full Google Places response (filtered to relevant fields) as JSON and exits. No interactive prompt. For piping into other tools.

## Google Places API Usage

### Endpoint

```
POST https://places.googleapis.com/v1/places:searchNearby
```

### Headers

```
Content-Type: application/json
X-Goog-Api-Key: $GOOGLE_PLACES_API_KEY
X-Goog-FieldMask: places.displayName,places.formattedAddress,places.rating,places.googleMapsUri,places.websiteUri,places.location
```

### Request body

```json
{
  "includedTypes": ["pizza_restaurant"],
  "maxResultCount": 5,
  "locationRestriction": {
    "circle": {
      "center": {"latitude": 40.6892, "longitude": -73.9857},
      "radius": 2000.0
    }
  }
}
```

### Response fields used

- `places[].displayName.text` — restaurant name
- `places[].formattedAddress` — street address
- `places[].rating` — star rating (float)
- `places[].googleMapsUri` — link to Google Maps listing
- `places[].websiteUri` — restaurant's own website (may be absent)
- `places[].location.latitude`, `places[].location.longitude` — for distance calculation

### Distance calculation

Approximate distance using the equirectangular projection (good enough for short distances):

```
dx = (lon2 - lon1) * cos(avg_lat) * 69.172
dy = (lat2 - lat1) * 69.172
distance_miles = sqrt(dx*dx + dy*dy)
```

This avoids needing `bc` or `awk` for haversine. Results sorted by distance ascending.

Note: bash can't do floating-point math natively. Use `awk` for the distance calculation and sorting.

### Pricing

Google Places Nearby Search: 5,000 free calls/month on the free tier. More than sufficient for a demo tool. Requires a Google Cloud project with Places API enabled and an API key.

## Interactive Display

```
$ ./pizza.sh

Finding your location...
  Brooklyn, NY (40.6892, -73.9857)

Finding pizza near you...

  1. Little Pizza Parlor        4.6  0.1 mi  192 Duffield St
  2. Joe's Pizza                4.4  0.3 mi  216 Flatbush Ave
  3. Juliana's Pizza            4.7  0.5 mi  19 Old Fulton St
  4. Front Street Pizza         4.2  0.6 mi  80 Front St
  5. Grimaldi's Pizzeria        4.3  0.7 mi  1 Front St

Pick a pizza place (1-5): 1

Opening Little Pizza Parlor...
```

## Browser Opening

When user picks a place:
1. If `websiteUri` exists, open that (more likely to have online ordering)
2. Otherwise, open `googleMapsUri`

Uses `open` on macOS. Could detect `xdg-open` on Linux for portability, but macOS-first is fine given whereami's primary audience.

## Error Handling

- `whereami` not found: print install instructions, exit 1
- `jq` not found: print `brew install jq`, exit 1
- `curl` not found: print error, exit 1
- `.env` missing or no API key: print setup instructions pointing to `.env.example`, exit 1
- Google Places returns error: print the error message, exit 1
- No results: "No pizza places found within {radius}m. Try a larger --radius."
- Invalid user input at prompt: re-prompt

## Blog Post Context

This project exists to showcase `whereami` in a fun, practical demo. The blog post arc:
- The problem: "I want pizza. I don't care where. I just want it near me."
- The tool: whereami gives you coordinates from the command line
- The solution: pipe those coordinates into a Google Places search
- The punchline: the final step is just `open $URL` — the terminal can find pizza but can't eat it

Companion to the headshot-background-normalize project, which showcases `loupe`. Both are Recurse Center projects demonstrating small, focused CLI tools composed with shell scripts.
