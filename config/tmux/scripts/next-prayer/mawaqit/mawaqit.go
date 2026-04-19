package mawaqit

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"

	"golang.org/x/text/unicode/norm"

	shared "github.com/ahmedelgabri/dotfiles/config/tmux/scripts/next-prayer/shared"
)

var base = "https://mawaqit.net/api/2.0"

type Times [6]string

type Mosque struct {
	UUID                  string    `json:"uuid"`
	Name                  string    `json:"name"`
	Type                  string    `json:"type"`
	Slug                  string    `json:"slug"`
	Latitude              float64   `json:"latitude"`
	Longitude             float64   `json:"longitude"`
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
	Jumua2                string    `json:"jumua2"`
	Jumua3                string    `json:"jumua3"`
	JumuaAsDuhr           bool      `json:"jumuaAsDuhr"`
	IqamaEnabled          bool      `json:"iqamaEnabled"`
}

type Response []Mosque

type Login struct {
	ID             int    `json:"id"`
	APIAccessToken string `json:"apiAccessToken"`
	APIQuota       int    `json:"apiQuota"`
	APICallNumber  int    `json:"apiCallNumber"`
}

type Params struct {
	Username  string
	Password  string
	Latitude  float64
	Longitude float64
	Mosque    string
}

func getToken(user string, pass string) (string, error) {
	client := &http.Client{}
	url := fmt.Sprintf("%s/me", base)
	req, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		return "", fmt.Errorf("failed to create auth request: %w", err)
	}

	req.Header.Add("Content-Type", "application/json")
	req.Header.Add("Authorization", fmt.Sprintf("Basic %s", base64.StdEncoding.EncodeToString([]byte(user+":"+pass))))

	resp, err := client.Do(req)
	if err != nil {
		return "", fmt.Errorf("auth request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("auth failed with status %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read auth response: %w", err)
	}

	var obj Login
	if err := json.Unmarshal(body, &obj); err != nil {
		return "", fmt.Errorf("failed to parse auth response: %w", err)
	}

	return obj.APIAccessToken, nil
}

type mawaqit struct {
	params Params
}

func New(params Params) mawaqit {
	return mawaqit{params: params}
}

func PrintHelp() {
	fmt.Printf(`
Usage
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
    --help           Print this help

Examples
    $ next-prayer mawaqit --latitude 52.3676 --longitude 4.9041
    $ next-prayer mawaqit --list-mosques --latitude 52.3676 --longitude 4.9041
`)
}

func searchMosques(token string, lat float64, lon float64) (Response, error) {
	client := &http.Client{}
	url := fmt.Sprintf("%s/mosque/search?lat=%f&lon=%f", base, lat, lon)
	req, err := http.NewRequest(http.MethodGet, url, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to create search request: %w", err)
	}

	req.Header.Add("Content-Type", "application/json")
	req.Header.Add("Authorization", token)

	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("mosque search request failed: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("mosque search failed with status %d", resp.StatusCode)
	}

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read search response: %w", err)
	}

	var mosques Response
	if err := json.Unmarshal(body, &mosques); err != nil {
		return nil, fmt.Errorf("failed to parse search response: %w", err)
	}

	return mosques, nil
}

func formatMosqueList(mosques Response) string {
	var b strings.Builder
	for i, m := range mosques {
		if i > 0 {
			b.WriteString("\n")
		}
		fmt.Fprintf(&b, "  Name:    %s\n", m.Name)
		if m.Label != "" && m.Label != m.Name {
			fmt.Fprintf(&b, "  Label:   %s\n", m.Label)
		}
		fmt.Fprintf(&b, "  Slug:    %s\n", m.Slug)
		if m.AssociationName != "" {
			fmt.Fprintf(&b, "  Assoc:   %s\n", m.AssociationName)
		}
		fmt.Fprintf(&b, "  UUID:    %s\n", m.UUID)
		fmt.Fprintf(&b, "  Dist:    %dm\n", m.Proximity)
		fmt.Fprintf(&b, "  Address: %s\n", m.Localisation)
	}
	return b.String()
}

// normalizeStr applies Unicode NFC normalization and lowercases the string
// for reliable comparison of Arabic and Latin text.
func normalizeStr(s string) string {
	return strings.ToLower(norm.NFC.String(s))
}

// findMosque matches the query against the list of mosques.
//
// Matching order:
//  1. Exact UUID match
//  2. Exact slug match
//  3. Substring match against name, label, and associationName (NFC-normalized)
//
// If the substring match finds multiple results, an error is returned listing
// the ambiguous matches so the user can refine their config.
func findMosque(mosques Response, query string) (Mosque, error) {
	if query == "" {
		return Mosque{}, fmt.Errorf("no mosque specified; set 'mosque' in config or use --mosque\n\nAvailable mosques:\n%s", formatMosqueList(mosques))
	}

	// Exact UUID match
	for _, m := range mosques {
		if m.UUID == query {
			return m, nil
		}
	}

	// Exact slug match
	for _, m := range mosques {
		if m.Slug == query {
			return m, nil
		}
	}

	// Substring match (Unicode-normalized) against name, label, associationName
	q := normalizeStr(query)
	var matches []Mosque
	for _, m := range mosques {
		if strings.Contains(normalizeStr(m.Name), q) ||
			strings.Contains(normalizeStr(m.Label), q) ||
			strings.Contains(normalizeStr(m.AssociationName), q) {
			matches = append(matches, m)
		}
	}

	switch len(matches) {
	case 0:
		return Mosque{}, fmt.Errorf("no mosque matching %q found\n\nAvailable mosques:\n%s", query, formatMosqueList(mosques))
	case 1:
		return matches[0], nil
	default:
		return Mosque{}, fmt.Errorf("multiple mosques match %q; use a UUID or slug instead:\n\n%s", query, formatMosqueList(Response(matches)))
	}
}

// ListMosques authenticates with Mawaqit and prints nearby mosques.
func ListMosques(params Params) error {
	if params.Username == "" || params.Password == "" {
		return fmt.Errorf("mawaqit username and password are required")
	}
	if params.Latitude == 0 || params.Longitude == 0 {
		return fmt.Errorf("latitude and longitude are required")
	}

	token, err := getToken(params.Username, params.Password)
	if err != nil {
		return err
	}

	mosques, err := searchMosques(token, params.Latitude, params.Longitude)
	if err != nil {
		return err
	}

	if len(mosques) == 0 {
		fmt.Println("No mosques found near this location.")
		return nil
	}

	fmt.Printf("Mosques near %.4f, %.4f:\n\n%s", params.Latitude, params.Longitude, formatMosqueList(mosques))
	return nil
}

func (m mawaqit) GetAPI() (shared.ApiData, error) {
	if m.params.Username == "" || m.params.Password == "" {
		return shared.ApiData{}, fmt.Errorf("mawaqit username and password are required")
	}
	if m.params.Latitude == 0 || m.params.Longitude == 0 {
		return shared.ApiData{}, fmt.Errorf("latitude and longitude are required")
	}

	token, err := getToken(m.params.Username, m.params.Password)
	if err != nil {
		return shared.ApiData{}, err
	}

	mosques, err := searchMosques(token, m.params.Latitude, m.params.Longitude)
	if err != nil {
		return shared.ApiData{}, err
	}

	if len(mosques) == 0 {
		return shared.ApiData{}, fmt.Errorf("no mosques found near %.4f, %.4f", m.params.Latitude, m.params.Longitude)
	}

	mosque, err := findMosque(mosques, m.params.Mosque)
	if err != nil {
		return shared.ApiData{}, err
	}

	times := mosque.Times

	return shared.ApiData{
		Timings: shared.AllTimes{
			Fajr:    times[0],
			Dhuhr:   times[2],
			Asr:     times[3],
			Maghrib: times[4],
			Isha:    times[5],
		},
	}, nil
}
