package mawaqit

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	shared "github.com/ahmedelgabri/dotfiles/config/tmux/scripts/next-prayer/shared"
)

var (
	base = "https://mawaqit.net/api/2.0"
)

type Times [6]string

type Mosque struct {
	Uuid                  string    `json:"uuid"`
	Name                  string    `json:"name"`
	Type                  string    `json:"type"`
	Slug                  string    `json:"slug"`
	Latitude              float32   `json:"latitude"`
	Longitude             float32   `json:"longitude"`
	AssociationName       string    `json:"associationName"`
	Phone                 string    `json:"phone"`
	PaymentWebsite        string    `json:"paymentWebsite"`
	Email                 string    `json:"email"`
	Site                  string    `json:"site"`
	Closed                bool      `json:"closed"`
	WomenSpace            bool      `json:"womenSpace"`
	JanazaPrayer          bool      `json:"janazaPrayer"`
	AidPrayer             bool      `json:"aidPrayer"`
	ChildrenCourses       bool      `json:"childrenCourses"`
	AdultCourses          bool      `json:"adultCourses"`
	RamadanMeal           bool      `json:"ramadanMeal"`
	HandicapAccessibility bool      `json:"handicapAccessibility"`
	Ablutions             bool      `json:"ablutions"`
	Parking               bool      `json:"parking"`
	Times                 Times     `json:"times"`
	Iqama                 [5]string `json:"iqama"`
	Jumua                 string    `json:"jumua"`
	Proximity             int       `json:"proximity"`
	Label                 string    `json:"label"`
	Localisation          string    `json:"localisation"`
	Image                 string    `json:"image"`
	Jumua2                string    `json:"jumua2"` // Huh?
	JumuaAsDuhr           bool      `json:"jumuaAsDuhr"`
}

type Response []Mosque

type Login struct {
	Id             int    `json:"id"`
	ApiAccessToken string `json:"apiAccessToken"`
	ApiQuota       int    `json:"apiQuota"`
	ApiCallNumber  int    `json:"apiCallNumber"`
}

type ApiData struct {
	Mosque  Mosque          `json:"mosque"`
	Timings shared.AllTimes `json:"timings"`
}

type Flags struct {
	Username  *string
	Password  *string
	Latitude  *string
	Longitude *string
}

func get_token(user string, pass string) (string, error) {
	client := &http.Client{}
	url := fmt.Sprintf("%s/me", base)
	req, err := http.NewRequest(http.MethodGet, url, nil)

	if err != nil {
		return "", err
	}

	req.Header.Add("Content-Type", "application/json")
	req.Header.Add("Authorization", fmt.Sprintf("Basic %s", base64.StdEncoding.EncodeToString([]byte(user+":"+pass))))

	resp, err := client.Do(req)

	if err != nil {
		return "", err
	}

	defer resp.Body.Close()

	if resp.StatusCode == http.StatusForbidden {
		fmt.Println(err)
	}

	body, err := io.ReadAll(resp.Body)

	if err != nil {
		return "", err
	}

	obj := Login{}
	err = json.Unmarshal(body, &obj)

	if err != nil {
		return "", err
	}

	return obj.ApiAccessToken, nil
}

type mawaqit struct {
	flags Flags
}

func New(flags Flags) mawaqit {
	return mawaqit{
		flags: flags,
	}
}

func (mawaqit) PrintHelp() {
	fmt.Printf(`
Usage
    $ next-prayer mawaqit [options]

Options
    --username      Mawaqit Username (default: MAWAQIT_USERNAME)
    --password      Mawaqit Password (default: MAWAQIT_PASSWORD)
    --latitude      Latitude (default: MAWAQIT_LATITUDE)
    --longitude     Longitude (default: MAWAQIT_LONGITUDE)
    --help          Print this help

Examples
    $ next-prayer mawaqit --user username --pass password --lat 52.354551 --lon 4.7391574
`)
}

func (m mawaqit) Get_api() (shared.ApiData, error) {
	apiToken, _ := get_token(*m.flags.Username, *m.flags.Password)
	client := &http.Client{}
	url := fmt.Sprintf("%s/mosque/search?lat=%s&lon=%s", base, *m.flags.Latitude, *m.flags.Longitude)
	req, err := http.NewRequest(http.MethodGet, url, nil)

	if err != nil {
		return shared.ApiData{}, err
	}

	req.Header.Add("Content-Type", "application/json")
	req.Header.Add("Authorization", apiToken)

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

	times := obj[0].Times

	return shared.ApiData{
		Mosque: obj[0],
		Timings: shared.AllTimes{
			Fajr:    times[0],
			Dhuhr:   times[2],
			Asr:     times[3],
			Maghrib: times[4],
			Isha:    times[5],
		},
	}, nil
}
