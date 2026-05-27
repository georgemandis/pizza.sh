# pizza.sh

Find pizza near you from the command line.

## Quick Start (macOS, no API key needed)

On macOS, you can combine [whereami](https://github.com/georgemandis/whereami) and [nearme](https://github.com/georgemandis/nearme) to find pizza with zero configuration:

```bash
brew install georgemandis/tap/whereami georgemandis/tap/nearme
whereami --json | nearme "pizza"
```

That's it. `whereami` gets your location via macOS location services, and `nearme` searches Apple Maps for nearby results. No API keys, no setup.

For more control — ratings, filtering, cross-platform support — read on.

## pizza.sh

Uses [whereami](https://github.com/georgemandis/whereami) to get your location, Google Places to find nearby pizza places, and opens your pick in the browser. Requires a Google Places API key but gives you richer results including ratings, and options like `--good` (curated results) and `--desperate` (anything pizza-adjacent).

### Usage

```bash
./pizza.sh
```

```
Finding your location...
  40.6892, -73.9857

Finding good pizza near you...

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
--good            Only good pizza places (default)
--desperate       Any pizza will do
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

# Any pizza will do
./pizza.sh --desperate
```

### Setup

#### Dependencies

- [whereami](https://github.com/georgemandis/whereami) — `brew install georgemandis/tap/whereami`
- [jq](https://jqlang.github.io/jq/) — `brew install jq`
- curl (system default)

#### Google Places API Key

1. Create a [Google Cloud project](https://console.cloud.google.com/)
2. Enable the [Places API (New)](https://console.cloud.google.com/apis/library/places-backend.googleapis.com)
3. Create an API key
4. Copy `.env.example` to `.env` and add your key:

```bash
cp .env.example .env
```

## How It Works

**Quick path** (`whereami | nearme`): `whereami` gets your coordinates via native OS location services, and `nearme` searches Apple Maps locally — no network API keys involved.

**Full path** (`pizza.sh`):
1. `whereami --json` returns your latitude and longitude
2. Google Places finds pizza restaurants within the search radius
   - `--good` (default): Nearby Search — curated results, proper pizza restaurants only
   - `--desperate`: Text Search for "pizza" — casts a wider net, finds anything pizza-adjacent
3. Results are sorted by distance and displayed as a numbered list
4. You pick one, and it opens in your browser

## Related Projects

- [whereami](https://github.com/georgemandis/whereami) — Get your location from the command line (macOS, Windows, Linux)
- [nearme](https://github.com/georgemandis/nearme) — Search for nearby places using Apple Maps (macOS only)

## Credits

Created by [George Mandis](https://george.mand.is) during [Recurse Center](https://www.recurse.com/).
