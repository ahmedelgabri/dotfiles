package shared

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path"
	"strings"
	"time"
)

var prayers = [5]string{"Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"}

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

func cacheKey(loc CacheLocation, now time.Time) string {
	date := now.Format("02-01-2006")
	city := strings.ToLower(strings.ReplaceAll(loc.City, " ", "-"))
	country := strings.ToLower(strings.ReplaceAll(loc.Country, " ", "-"))

	if city == "" && country == "" {
		return fmt.Sprintf(".prayer-%s.json", date)
	}

	return fmt.Sprintf(".prayer-%s_%s_%s.json", city, country, date)
}

func getData(source Source, loc CacheLocation, now time.Time) ([]byte, error) {
	cache := path.Join(os.TempDir(), cacheKey(loc, now))

	body, err := os.ReadFile(cache)
	if err != nil {
		if !errors.Is(err, os.ErrNotExist) {
			return nil, fmt.Errorf("failed to read cache %s: %w", cache, err)
		}

		data, err := source.GetAPI()
		if err != nil {
			return nil, err
		}

		file, err := json.MarshalIndent(data, "", " ")
		if err != nil {
			return nil, fmt.Errorf("failed to marshal API data: %w", err)
		}

		if err := os.WriteFile(cache, file, 0644); err != nil {
			return nil, fmt.Errorf("failed to write cache %s: %w", cache, err)
		}

		return file, nil
	}

	return body, nil
}

func GetPrayer(source Source, loc CacheLocation) (Output, error) {
	now := time.Now().In(time.Local)
	nowFormatted := now.Format("02 Jan 2006")

	data, err := getData(source, loc, now)
	if err != nil {
		return Output{}, err
	}

	var jsonData ApiData
	if err := json.Unmarshal(data, &jsonData); err != nil {
		return Output{}, fmt.Errorf("failed to parse cached data: %w", err)
	}

	ishaTime, err := getPrayerTime(fmt.Sprintf("%s %s", nowFormatted, jsonData.Timings.Isha))
	if err != nil {
		return Output{}, fmt.Errorf("failed to parse Isha time: %w", err)
	}

	// After Isha, show next Fajr
	if now.After(ishaTime) {
		return Output{
			Item:          fmt.Sprintf("%s: %s", prayers[0], jsonData.Timings.Fajr),
			TimeRemaining: -1,
		}, nil
	}

	for _, prayerName := range prayers {
		var prayerTimeStr string
		switch prayerName {
		case "Fajr":
			prayerTimeStr = jsonData.Timings.Fajr
		case "Dhuhr":
			prayerTimeStr = jsonData.Timings.Dhuhr
		case "Asr":
			prayerTimeStr = jsonData.Timings.Asr
		case "Maghrib":
			prayerTimeStr = jsonData.Timings.Maghrib
		case "Isha":
			prayerTimeStr = jsonData.Timings.Isha
		default:
			continue
		}

		prayerTime, err := getPrayerTime(fmt.Sprintf("%s %s", nowFormatted, prayerTimeStr))
		if err != nil {
			continue
		}

		if prayerTime.After(now) {
			remaining := int(prayerTime.Sub(now).Minutes())
			return Output{
				Item:          fmt.Sprintf("%s: %s", prayerName, prayerTimeStr),
				TimeRemaining: remaining,
			}, nil
		}
	}

	return Output{
		Item:          "NO RESULTS",
		TimeRemaining: -1,
	}, nil
}
