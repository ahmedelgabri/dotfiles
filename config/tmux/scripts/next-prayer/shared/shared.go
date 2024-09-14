package shared

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path"
	"reflect"
	"time"
)

var (
	prayers = [5]string{"Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"}
)

type AllTimes struct {
	Fajr    string
	Dhuhr   string
	Asr     string
	Maghrib string
	Isha    string
}

type Output struct {
	Item          string
	TimeRemaining int
}

type ApiData struct {
	Mosque  interface{} `json:"mosque"`
	Timings AllTimes    `json:"timings"`
}

type Source interface {
	Get_api() (ApiData, error)
}

func get_prayer_time(timeStr string) (time.Time, error) {
	return time.ParseInLocation("02 Jan 2006 15:04", timeStr, time.Local)
}

func get_field(v *ApiData, field string) string {
	r := reflect.ValueOf(v.Timings)
	f := reflect.Indirect(r).FieldByName(field)
	return string(f.String())
}

// @TODO
// CHange how we cache the data so we can check if the location changed and
// update the cache accordingly.
//
// Also we need to define what does a location change mean, lat/long can change
// easily instead we want to check the city and/or country
//
// So cache key should probably be the city and country like this "city_country"
func get_data(source Source, now time.Time) ([]byte, error) {
	today_date := now.Format("02-01-2006")
	cache := path.Join(os.TempDir(), "."+today_date+".json")

	body, err := os.ReadFile(cache)

	if err != nil {
		if !errors.Is(err, os.ErrNotExist) {
			return []byte{}, err
		}

		data, err := source.Get_api()

		if err != nil {
			return []byte{}, err
		}

		file, _ := json.MarshalIndent(data, "", " ")

		_ = os.WriteFile(cache, file, 0644)

		return file, nil
	}

	return body, nil
}

// @TODO
// Revisit this whole time parsing logic
// the times I get from the APIs are in local timezone depending on the location
// so I building a time object and then converting it to the local timezone
// this will not always work. It's better to convert to UTC and then convert it to the local timezone
func Get_prayer(source Source) Output {
	now := time.Now().In(time.Local)
	nowFormatted := now.Format("02 Jan 2006")
	data, _ := get_data(source, now)
	jsonData := ApiData{}

	if err := json.Unmarshal(data, &jsonData); err != nil {
		panic(err)
	}

	isha_time, _ := get_prayer_time(fmt.Sprintf("%s %s", nowFormatted, jsonData.Timings.Isha))

	if now.After(isha_time) {
		return Output{
			Item:          fmt.Sprintf("%s: %s", prayers[0], jsonData.Timings.Fajr),
			TimeRemaining: -1,
		}
	}

	for _, prayer := range prayers {
		prayer_time := get_field(&jsonData, prayer)
		prayer_time_formatted, _ := get_prayer_time(fmt.Sprintf("%s %s", nowFormatted, prayer_time))

		if prayer_time_formatted.After(now) {
			time_remaining := prayer_time_formatted.Sub(now)
			time_remaining_diff := (time_remaining).Minutes()

			return Output{
				Item:          fmt.Sprintf("%s: %s", prayer, prayer_time),
				TimeRemaining: int(time_remaining_diff),
			}
		}
	}

	return Output{
		Item:          "NO RESULTS",
		TimeRemaining: -1,
	}
}
