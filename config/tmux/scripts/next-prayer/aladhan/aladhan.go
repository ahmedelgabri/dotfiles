package aladhan

import (
	"encoding/json"
	"fmt"
	"io"
	"math/rand"
	"net/http"

	shared "github.com/ahmedelgabri/dotfiles/config/tmux/scripts/next-prayer/shared"
)

var agents = [6]string{
	"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/60.0.3112.113 Safari/537.36",
	"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.47 Safari/537.36",
	"Mozilla/5.0 (Windows NT 6.1; WOW64; rv:54.0) Gecko/20100101 Firefox/54.0",
	"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/601.7.7 (KHTML, like Gecko) Version/9.1.2 Safari/601.7.7",
	"Mozilla/5.0 (iPhone; CPU iPhone OS 11_0 like Mac OS X) AppleWebKit/604.1.38 (KHTML, like Gecko) Version/11.0 Mobile/15A372 Safari/604.1",
	"Mozilla",
}

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

type Params struct {
	City    string
	Country string
	Method  int
	Tune    string
}

type aladhan struct {
	params Params
}

func New(params Params) aladhan {
	return aladhan{params: params}
}

func PrintHelp() {
	fmt.Printf(`
Usage
    $ next-prayer aladhan [options]

Options
    --country   Country name or code (e.g. "Netherlands" or "NL")
    --city      City name (e.g. "Amsterdam")
    --method    Calculation method (e.g. 3)
    --tune      Prayer time tuning
    --config    Config file path override
    --help      Print this help

Examples
    $ next-prayer aladhan --country NL --city Amsterdam --method 3
`)
}

func (a aladhan) GetAPI() (shared.ApiData, error) {
	if a.params.City == "" {
		return shared.ApiData{}, fmt.Errorf("aladhan city is required")
	}
	if a.params.Country == "" {
		return shared.ApiData{}, fmt.Errorf("aladhan country is required")
	}
	if a.params.Method == 0 {
		return shared.ApiData{}, fmt.Errorf("aladhan method is required")
	}

	client := &http.Client{}
	url := fmt.Sprintf("https://api.aladhan.com/v1/timingsByCity?city=%s&country=%s&method=%d&tune=%s",
		a.params.City, a.params.Country, a.params.Method, a.params.Tune)

	req, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		return shared.ApiData{}, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Add("Host", "api.aladhan.com")
	req.Header.Add("User-Agent", agents[rand.Intn(len(agents))])

	resp, err := client.Do(req)
	if err != nil {
		return shared.ApiData{}, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return shared.ApiData{}, fmt.Errorf("aladhan API returned status %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return shared.ApiData{}, fmt.Errorf("failed to read response: %w", err)
	}

	var obj Response
	if err := json.Unmarshal(body, &obj); err != nil {
		return shared.ApiData{}, fmt.Errorf("failed to parse response: %w", err)
	}

	return shared.ApiData{
		Timings: obj.Data.Timings,
	}, nil
}
