# pizza.sh

Find pizza near you from the command line.

Uses [whereami](https://github.com/georgemandis/whereami) to get your location, Google Places to find nearby pizza places, and opens your pick in the browser.

## Usage

```bash
./pizza.sh
```

```
Finding your location...
  40.6892, -73.9857

Finding pizza near you...

  1. Little Pizza Parlor  4.7  0.2 mi  192 Duffield St, Brooklyn, NY 11201, USA
  2. Lucali               4.2  0.9 mi  575 Henry St, Brooklyn, NY 11231, USA
  3. L&B Spumoni Gardens  4.4  1 mi    46 Old Fulton St, Brooklyn, NY 11201, USA
  4. Grimaldi's Pizzeria  4.2  1 mi    1 Front St, Brooklyn, NY 11201, USA
  5. Juliana's            4.6  1 mi    19 Old Fulton St, Brooklyn, NY 11201, USA

Pick a pizza place (1-5): 1

Opening Little Pizza Parlor...
```

### Options

```
--mock=LAT,LON    Use provided coordinates instead of whereami
--radius=N        Search radius in meters (default: 2000)
--count=N         Number of results (default: 5, max: 20)
--json            Output JSON instead of interactive list
-h, --help        Show help
```

### Examples

```bash
# Use mock coordinates (no whereami needed)
./pizza.sh --mock=40.7128,-74.0060

# Search a wider area, show more results
./pizza.sh --radius=5000 --count=10

# Pipe JSON to other tools
./pizza.sh --mock=40.7128,-74.0060 --json | jq '.[0].name'
```

## Setup

### Dependencies

- [whereami](https://github.com/georgemandis/whereami) — `brew install georgemandis/tap/whereami`
- [jq](https://jqlang.github.io/jq/) — `brew install jq`
- curl (system default)

### Google Places API Key

1. Create a [Google Cloud project](https://console.cloud.google.com/)
2. Enable the [Places API (New)](https://console.cloud.google.com/apis/library/places-backend.googleapis.com)
3. Create an API key
4. Copy `.env.example` to `.env` and add your key:

```bash
cp .env.example .env
```

## How It Works

1. `whereami --json` returns your latitude and longitude using native OS location services
2. Google Places Nearby Search finds pizza restaurants within the search radius
3. Results are sorted by distance and displayed as a numbered list
4. You pick one, and it opens in your browser

## Credits

Created by [George Mandis](https://george.mand.is) during [Recurse Center](https://www.recurse.com/).
