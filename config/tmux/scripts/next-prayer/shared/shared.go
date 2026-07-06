package shared

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"
)

type AllTimes struct {
	Fajr    string `json:"fajr"`
	Dhuhr   string `json:"dhuhr"`
	Asr     string `json:"asr"`
	Maghrib string `json:"maghrib"`
	Isha    string `json:"isha"`
}

type Output struct {
	Item          string
	TimeRemaining int
}

type MosqueInfo struct {
	UUID            string `json:"uuid,omitempty"`
	Name            string `json:"name,omitempty"`
	Label           string `json:"label,omitempty"`
	Slug            string `json:"slug,omitempty"`
	AssociationName string `json:"associationName,omitempty"`
}

type ApiData struct {
	Timings AllTimes    `json:"timings"`
	Mosque  *MosqueInfo `json:"mosque,omitempty"`
}

type Source interface {
	GetAPI() (ApiData, error)
}

// CacheLocation identifies the user's location for cache keying. When the
// city or country changes the cache is invalidated so prayer times are
// re-fetched for the new location.
type CacheLocation struct {
	City    string
	Country string
}

func getPrayerTime(timeStr string) (time.Time, error) {
	return time.ParseInLocation("02 Jan 2006 15:04", timeStr, time.Local)
}

type namedTime struct {
	Name string
	Time string
}

func orderedTimings(t AllTimes) []namedTime {
	return []namedTime{
		{"Fajr", t.Fajr},
		{"Dhuhr", t.Dhuhr},
		{"Asr", t.Asr},
		{"Maghrib", t.Maghrib},
		{"Isha", t.Isha},
	}
}

// validateTimings rejects API or cached data whose prayer times cannot be
// parsed, so a bad response is never written to the cache and a bad cache
// entry is refetched instead of poisoning the rest of the day.
func validateTimings(t AllTimes) error {
	for _, p := range orderedTimings(t) {
		if _, err := time.Parse("15:04", p.Time); err != nil {
			return fmt.Errorf("invalid %s time %q", p.Name, p.Time)
		}
	}
	return nil
}

func cacheKey(loc CacheLocation, now time.Time) string {
	date := now.Format("02-01-2006")
	city := strings.ToLower(strings.ReplaceAll(loc.City, " ", "-"))
	country := strings.ToLower(strings.ReplaceAll(loc.Country, " ", "-"))

	if city == "" && country == "" {
		return fmt.Sprintf(".prayer-%s.json", date)
	}

	return fmt.Sprintf(".prayer-%s_%s_%s.json", city, country, date)
}

// readCache returns the cached data when it exists and passes validation.
// Any unreadable, corrupt, or invalid cache file is treated as a miss so
// the data gets refetched (and the file rewritten).
func readCache(cache string) (ApiData, bool) {
	body, err := os.ReadFile(cache)
	if err != nil {
		return ApiData{}, false
	}

	var data ApiData
	if err := json.Unmarshal(body, &data); err != nil {
		return ApiData{}, false
	}

	if err := validateTimings(data.Timings); err != nil {
		return ApiData{}, false
	}

	return data, true
}

func getData(source Source, loc CacheLocation, now time.Time) (ApiData, error) {
	cache := filepath.Join(os.TempDir(), cacheKey(loc, now))

	if data, ok := readCache(cache); ok {
		return data, nil
	}

	data, err := source.GetAPI()
	if err != nil {
		return ApiData{}, err
	}

	if err := validateTimings(data.Timings); err != nil {
		return ApiData{}, err
	}

	file, err := json.MarshalIndent(data, "", " ")
	if err != nil {
		return ApiData{}, fmt.Errorf("failed to marshal API data: %w", err)
	}

	if err := os.WriteFile(cache, file, 0644); err != nil {
		return ApiData{}, fmt.Errorf("failed to write cache %s: %w", cache, err)
	}

	return data, nil
}

func GetPrayer(source Source, loc CacheLocation) (Output, error) {
	now := time.Now().In(time.Local)
	nowFormatted := now.Format("02 Jan 2006")

	data, err := getData(source, loc, now)
	if err != nil {
		return Output{}, err
	}

	ishaTime, err := getPrayerTime(fmt.Sprintf("%s %s", nowFormatted, data.Timings.Isha))
	if err != nil {
		return Output{}, fmt.Errorf("failed to parse Isha time: %w", err)
	}

	// After Isha, show next Fajr. Today's cached Fajr time is used as an
	// approximation; tomorrow's actual time may differ slightly until the
	// cache rolls over at midnight.
	if now.After(ishaTime) {
		return Output{
			Item:          fmt.Sprintf("Fajr: %s", data.Timings.Fajr),
			TimeRemaining: -1,
		}, nil
	}

	for _, prayer := range orderedTimings(data.Timings) {
		prayerTime, err := getPrayerTime(fmt.Sprintf("%s %s", nowFormatted, prayer.Time))
		if err != nil {
			continue
		}

		if prayerTime.After(now) {
			remaining := int(prayerTime.Sub(now).Minutes())
			return Output{
				Item:          fmt.Sprintf("%s: %s", prayer.Name, prayer.Time),
				TimeRemaining: remaining,
			}, nil
		}
	}

	return Output{
		Item:          "NO RESULTS",
		TimeRemaining: -1,
	}, nil
}
