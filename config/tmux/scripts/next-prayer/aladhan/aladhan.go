package aladhan

import (
	"encoding/json"
	"fmt"
	"io"
	"math/rand"
	"net/http"
	"time"

	shared "github.com/ahmedelgabri/dotfiles/config/tmux/scripts/next-prayer/shared"
)

var (
	agents = [6]string{
		"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36",
		"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.47 Safari/537.36",
		"Mozilla/5.0 (Windows NT 6.1; WOW64; rv:54.0) Gecko/20100101 Firefox/54.0",
		"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/601.7.7 (KHTML, like Gecko) Version/9.1.2 Safari/601.7.7",
		"Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1",
		"Mozilla",
	}
)

type Date struct {
	Readable string `json:"readable"`
}

type Response struct {
	Code   int    `json:"code"`
	Status string `json:"status"`
	Data   struct {
		Timings shared.AllTimes `json:"timings"`
		Date    Date            `json:"date"`
	} `json:"data"`
}

type Flags struct {
	City    *string
	Country *string
	Method  *int
	Tune    *string
}

type aladahan struct {
	flags Flags
}

func New(flags Flags) aladahan {
	return aladahan{
		flags: flags,
	}
}

func (aladahan) PrintHelp() {
	fmt.Printf(`
Usage
    $ next-prayer aladhan [options]

Options
    --country   The country you want prayers time for (i.e. United Kingdom or UK)
    --city      The city you want prayers time for (i.e. London)
    --method    Calculation method (i.e. 3)
    --tune      Prayer times tuning (i.e. "")
    --help      Print this help

Examples
    $ next-prayer aladhan --country nl --city amsterdam --method 3
`)
}

func (a aladahan) Get_api() (shared.ApiData, error) {
	client := &http.Client{}
	url := fmt.Sprintf("https://api.aladhan.com/v1/timingsByCity?city=%s&country=%s&method=%d&tune=%s", *a.flags.City, *a.flags.Country, *a.flags.Method, *a.flags.Tune)
	req, err := http.NewRequest(http.MethodGet, url, nil)

	if err != nil {
		return shared.ApiData{}, err
	}

	rand.New(rand.NewSource(time.Now().Unix()))
	req.Header.Add("Host", "api.aladhan.com")
	req.Header.Add("User-Agent", agents[rand.Intn(len(agents))])

	resp, err := client.Do(req)

	if err != nil {
		return shared.ApiData{}, err
	}

	defer resp.Body.Close()

	if resp.StatusCode == http.StatusForbidden {
		fmt.Println(err)
	}

	body, err := io.ReadAll(resp.Body)

	if err != nil {
		return shared.ApiData{}, err
	}

	obj := Response{}
	err = json.Unmarshal(body, &obj)

	if err != nil {
		return shared.ApiData{}, err
	}

	return shared.ApiData{
		Timings: obj.Data.Timings,
	}, nil
}
