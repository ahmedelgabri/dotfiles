# next-prayer

A CLI tool that displays the next Islamic prayer time. Designed to run inside a
tmux status bar but works standalone too.

Supports two data sources:

- **[Mawaqit](https://mawaqit.net/)** — mosque-specific prayer times (requires
  an account)
- **[Aladhan](https://aladhan.com/)** — city-level calculated prayer times
  (public API, no account needed)

## Prerequisites

- **Mawaqit**: a free account at [mawaqit.net](https://mawaqit.net/). Username
  and password are needed for API access.
- **Aladhan**: no account required.

## Configuration

Configuration lives at `$XDG_CONFIG_HOME/prayer-times/config.toml` (typically
`~/.config/prayer-times/config.toml`).

Both `[mawaqit]` and `[aladhan]` sections should be populated so either source
can be used depending on whether location data is available.

```toml
[mawaqit]
# Username and password are best set via MAWAQIT_USERNAME / MAWAQIT_PASSWORD
# environment variables to keep credentials out of the config file.
latitude = 52.3676
longitude = 4.9041
mosque = "amsterdam-blue-mosque"

[aladhan]
city = "Amsterdam"
country = "NL"
method = 12
tune = "0,-18,0,0,0,0,0,12,0"
```

### Resolution order

Every setting follows the same precedence:

1. **CLI flag** (highest priority)
2. **Config file**
3. **Environment variable**

If none of these provide a value, the tool exits with an error. There are no
hardcoded defaults.

### Environment variables

| Variable            | Description                      |
| ------------------- | -------------------------------- |
| `MAWAQIT_USERNAME`  | Mawaqit account username         |
| `MAWAQIT_PASSWORD`  | Mawaqit account password         |
| `MAWAQIT_LATITUDE`  | Latitude for mosque search       |
| `MAWAQIT_LONGITUDE` | Longitude for mosque search      |
| `ALADHAN_CITY`      | City for prayer time calculation |
| `ALADHAN_COUNTRY`   | Country name or code             |
| `ALADHAN_METHOD`    | Calculation method number        |
| `ALADHAN_TUNE`      | Prayer time tuning offsets       |

## Mosque selection

Mawaqit returns multiple mosques near the given coordinates. The `mosque` config
field (or `--mosque` flag) selects which one to use. It is matched against
several fields in the following order:

1. **Exact UUID** — e.g. `"594fd1c6-7a3c-4489-a693-b40cbb07510f"`
2. **Exact slug** — e.g. `"amsterdam-blue-mosque"`
3. **Substring match** against `name`, `label`, and `associationName` — e.g.
   `"Blue Mosque"` or `"المسجد الأزرق"`

Substring matching is Unicode-normalized (NFC) so Arabic and other non-Latin
names work reliably regardless of encoding form.

If the substring matches multiple mosques, the tool errors with a list of the
ambiguous matches (including UUIDs and slugs) so you can pick a more specific
value.

### Finding your mosque

Use `--list-mosques` to discover mosques near a location:

```
$ next-prayer mawaqit --list-mosques --latitude 52.3676 --longitude 4.9041

Mosques near 52.3676, 4.9041:

  Name:    Amsterdam Blue Mosque
  Slug:    amsterdam-blue-mosque
  UUID:    594fd1c6-7a3c-4489-a693-b40cbb07510f
  Dist:    850m
  Address: Keizersgracht 123, Amsterdam, Netherlands
```

Copy the `Name`, `Slug`, or `UUID` into your config file.

## CLI usage

```
Usage
    $ next-prayer <command> [options]

Commands
    mawaqit     Get prayer times from Mawaqit
    aladhan     Get prayer times from Aladhan

Options
    --version   Print the CLI version
    --help      Print help
```

### Mawaqit

```
$ next-prayer mawaqit [options]

Options
    --username       Mawaqit username
    --password       Mawaqit password
    --latitude       Latitude
    --longitude      Longitude
    --city           City (for cache keying)
    --country        Country (for cache keying)
    --mosque         Mosque name, label, slug, associationName, or UUID
    --list-mosques   List nearby mosques and exit
    --config         Config file path override
    --help           Print help
```

Example:

```bash
next-prayer mawaqit --latitude 52.3676 --longitude 4.9041
```

### Aladhan

```
$ next-prayer aladhan [options]

Options
    --city      City name
    --country   Country name or code
    --method    Calculation method
    --tune      Prayer time tuning
    --config    Config file path override
    --help      Print help
```

Example:

```bash
next-prayer aladhan --city Amsterdam --country NL --method 3
```

### Aladhan calculation methods

The `method` field corresponds to a calculation method from the
[Aladhan API](https://aladhan.com/prayer-times-api#GetCalendarByCitys). Common
values:

| Method | Organization                                        |
| ------ | --------------------------------------------------- |
| 1      | University of Islamic Sciences, Karachi             |
| 2      | Islamic Society of North America (ISNA)             |
| 3      | Muslim World League                                 |
| 4      | Umm Al-Qura University, Makkah                      |
| 5      | Egyptian General Authority of Survey                |
| 12     | UOIF (Union des Organisations Islamiques de France) |

## Caching

Prayer times are cached daily in `$TMPDIR` to avoid repeated API calls. The
cache key includes the date and location (city + country), so the cache is
automatically invalidated when:

- A new day starts
- The user's location changes (e.g. travelling)

Cache files are named `.prayer-<city>_<country>_<DD-MM-YYYY>.json`.

## tmux integration

The companion script `get-prayer` is designed to be called from `tmux.conf`:

```tmux
set -g status-right "#(~/.config/tmux/scripts/get-prayer)"
```

`get-prayer` reads location data from `$TMPDIR/.location.json` (written by
[Hammerspoon](https://www.hammerspoon.org/)) and decides which source to use:

- **Location available** → uses Mawaqit with the current lat/lon, passing city
  and country for cache keying
- **Location unavailable** → falls back to Aladhan using values from the config
  file

This means prayer times update automatically when:

- tmux refreshes its status bar (controlled by `status-interval`)
- The location changes (Hammerspoon writes new coordinates, the cache key
  changes, and the next tmux refresh fetches fresh data)

## Building

```bash
# Build locally
make build

# Build with Nix
nix build .#next-prayer
```
