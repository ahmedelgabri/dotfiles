package main

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"math/rand"
	"net/http"
	"os"
	"path"
	"reflect"
	"time"
)

// # TODO

// - Refetch if city, country or method changed
// - Means we need to store this info in the cache too
// - Can we simplify using only city? instead of city + country combo
// - Add debug? logging? verbose?

var (
	version string
	red     = "\033[1;31;40m"
	prayers = [5]string{"Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"}
	agents  = [6]string{
		"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36",
		"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.47 Safari/537.36",
		"Mozilla/5.0 (Windows NT 6.1; WOW64; rv:54.0) Gecko/20100101 Firefox/54.0",
		"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/601.7.7 (KHTML, like Gecko) Version/9.1.2 Safari/601.7.7",
		"Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1",
		"Mozilla",
	}
)

type AllTimes struct {
	Fajr       string
	Sunrise    string
	Dhuhr      string
	Asr        string
	Sunset     string
	Maghrib    string
	Isha       string
	Imsak      string
	Midnight   string
	Firstthird string
	Lastthird  string
}

type Date struct {
	Readable string `json:"readable"`
}

type Response struct {
	Code   int    `json:"code"`
	Status string `json:"status"`
	Data   struct {
		Timings AllTimes `json:"timings"`
		Date    Date     `json:"date"`
	} `json:"data"`
}

type ApiData struct {
	Timings      AllTimes `json:"timings"`
	ReadableDate string   `json:"readable_date"`
}

type Flags struct {
	City    *string
	Country *string
	Method  *int
	Tune    *string
}

func get_api(flags Flags) (ApiData, error) {
	client := &http.Client{}
	// TODO: use &iso8601=true
	url := fmt.Sprintf("https://api.aladhan.com/v1/timingsByCity?city=%s&country=%s&method=%d&tune=%s", *flags.City, *flags.Country, *flags.Method, *flags.Tune)
	req, err := http.NewRequest(http.MethodGet, url, nil)

	if err != nil {
		return ApiData{}, err
	}

	rand.Seed(time.Now().Unix())
	req.Header.Add("User-Agent", agents[rand.Intn(len(agents))])

	resp, err := client.Do(req)

	if err != nil {
		return ApiData{}, err
	}

	defer resp.Body.Close()

	if resp.StatusCode == http.StatusForbidden {
		fmt.Println(err)
	}

	body, err := io.ReadAll(resp.Body)

	if err != nil {
		return ApiData{}, err
	}

	obj := Response{}
	err = json.Unmarshal(body, &obj)

	if err != nil {
		return ApiData{}, err
	}

	return ApiData{
		Timings:      obj.Data.Timings,
		ReadableDate: obj.Data.Date.Readable,
	}, nil
}

func get_data(now time.Time, flags Flags) ([]byte, error) {
	today_date := now.Format("02-01-2006")
	cache := path.Join(os.TempDir(), "."+today_date+".json")

	body, err := os.ReadFile(cache)

	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			data, err := get_api(flags)

			if err != nil {
				return []byte{}, err
			}

			file, _ := json.MarshalIndent(data, "", " ")

			_ = os.WriteFile(cache, file, 0644)

			return file, nil
		} else {
			return []byte{}, err
		}
	}

	return body, nil
}

func get_prayer_time(timeStr string) (time.Time, error) {
	return time.ParseInLocation("02 Jan 2006 15:04", timeStr, time.Local)
}

func get_field(v *ApiData, field string) string {
	r := reflect.ValueOf(v.Timings)
	f := reflect.Indirect(r).FieldByName(field)
	return string(f.String())
}

func get_prayer(now time.Time, flags Flags) string {
	data, _ := get_data(now, flags)
	jsonData := ApiData{}

	if err := json.Unmarshal(data, &jsonData); err != nil {
		panic(err)
	}

	isha_time, _ := get_prayer_time(fmt.Sprintf("%s %s", jsonData.ReadableDate, jsonData.Timings.Isha))

	// fmt.Println(string(u), d.ReadableDate, d.Timings, prayers[len(prayers)-1], after_isha)

	if now.After(isha_time) {
		return fmt.Sprintf("%s: %s", prayers[0], jsonData.Timings.Fajr)
	}

	for _, prayer := range prayers {
		prayer_time := get_field(&jsonData, prayer)
		prayer_time_formatted, _ := get_prayer_time(fmt.Sprintf("%s %s", jsonData.ReadableDate, prayer_time))

		if prayer_time_formatted.After(now) {
			time_remaning := prayer_time_formatted.Sub(now)
			time_remaning_diff := (time_remaning).Minutes()
			color := ""

			if time_remaning_diff <= 30 {
				color = red
			}

			return fmt.Sprintf("%s%s: %s", color, prayer, prayer_time)
		}
	}

	return red + " NO RESULTS"
}

func print_help() {
	fmt.Printf(`
Usage
	$ next-prayer --country <country> --city <city> --method <method> --tune <tune>

Options
	--country   The country you want prayers time for (i.e. United Kingdom or UK)
	--city      The city you want prayers time for (i.e. London)
	--method    Calculation method (i.e. 3)
	--tune      Prayer times tuning (i.e. "0,-18,0,0,0,0,0,12,0")
	--version   Print the CLI version (%s)
	--help      Print this help

Examples
	$ next-prayer --country nl --city amsterdam --method 3
`, version)
}

func init() {
	if _, isTmux := os.LookupEnv("TMUX"); isTmux {
		red = "#[fg=red]"
	}
}

func main() {
	// https://aladhan.com/prayer-times-api#GetCalendarByCitys
	cityFlag := flag.String("city", "Almere", "City name")
	countryFlag := flag.String("country", "nl", "Country name")
	methodFlag := flag.Int("method", 12, "Prayer method")
	tuneFlag := flag.String("tune", "0,-18,0,0,0,0,0,12,0", "Prayer time tuning")
	versionFlag := flag.Bool("version", false, "CLI version")
	helpFlag := flag.Bool("help", false, "Help!")

	flag.Parse()

	if *helpFlag {
		print_help()
		return
	}

	if *versionFlag {
		fmt.Println(version)
		return
	}

	result := get_prayer(time.Now(), Flags{
		Country: countryFlag,
		City:    cityFlag,
		Method:  methodFlag,
		Tune:    tuneFlag,
	})

	fmt.Println(result)
}
