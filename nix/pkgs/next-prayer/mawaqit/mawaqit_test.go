package mawaqit

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"reflect"
	"strings"
	"sync/atomic"
	"testing"

	"github.com/ahmedelgabri/dotfiles/config/tmux/scripts/next-prayer/shared"
)

var testMosques = Response{
	{UUID: "uuid-blue", Slug: "blue-mosque", Name: "Blue Mosque", Label: "المسجد الأزرق", AssociationName: "Stichting Blauw", Proximity: 850, Localisation: "Amsterdam", Times: Times{"04:30", "06:00", "13:36", "17:47", "21:24", "23:07"}},
	{UUID: "uuid-central", Slug: "central-mosque", Name: "Central Mosque", Label: "Café", Proximity: 1200, Localisation: "Delft"},
}

func TestFindMosque(t *testing.T) {
	for _, tc := range []struct {
		name  string
		query string
		index int
	}{
		{"UUID", "uuid-blue", 0},
		{"slug", "central-mosque", 1},
		{"name case insensitive", "BLUE", 0},
		{"Arabic label", "الأزرق", 0},
		{"association", "BLAUW", 0},
		{"Unicode normalization", "CAFE\u0301", 1},
	} {
		t.Run(tc.name, func(t *testing.T) {
			got, err := findMosque(testMosques, tc.query)
			if err != nil {
				t.Fatal(err)
			}
			if got != testMosques[tc.index] {
				t.Errorf("selected %+v, want %+v", got, testMosques[tc.index])
			}
		})
	}
	t.Run("UUID wins over slug and substring", func(t *testing.T) {
		mosques := Response{{UUID: "other", Slug: "exact", Name: "exact"}, {UUID: "exact", Slug: "second"}}
		got, err := findMosque(mosques, "exact")
		if err != nil || got != mosques[1] {
			t.Fatalf("selected %+v, error %v", got, err)
		}
	})
	t.Run("slug wins over substring", func(t *testing.T) {
		mosques := Response{{UUID: "first", Name: "exact"}, {UUID: "second", Slug: "exact"}}
		got, err := findMosque(mosques, "exact")
		if err != nil || got != mosques[1] {
			t.Fatalf("selected %+v, error %v", got, err)
		}
	})
	for _, tc := range []struct {
		query string
		want  string
	}{
		{"", "no mosque specified; set 'mosque' in config or use --mosque"},
		{"missing", `no mosque matching "missing" found`},
		{"Mosque", `multiple mosques match "Mosque"; use a UUID or slug instead:`},
	} {
		t.Run("error/"+tc.query, func(t *testing.T) {
			got, err := findMosque(testMosques, tc.query)
			if err == nil || !strings.HasPrefix(err.Error(), tc.want) {
				t.Fatalf("error = %v, want prefix %q", err, tc.want)
			}
			if got != (Mosque{}) || !strings.Contains(err.Error(), "uuid-blue") || !strings.Contains(err.Error(), "central-mosque") {
				t.Errorf("selection errors should return no mosque and list candidates: %+v, %v", got, err)
			}
		})
	}
}

func TestFormatMosqueList(t *testing.T) {
	want := "  Name:    Blue Mosque\n  Label:   المسجد الأزرق\n  Slug:    blue-mosque\n  Assoc:   Stichting Blauw\n  UUID:    uuid-blue\n  Dist:    850m\n  Address: Amsterdam\n\n  Name:    Central Mosque\n  Label:   Café\n  Slug:    central-mosque\n  UUID:    uuid-central\n  Dist:    1200m\n  Address: Delft\n"
	if got := formatMosqueList(testMosques); got != want {
		t.Errorf("list = %q, want %q", got, want)
	}
	if got := formatMosqueList(nil); got != "" {
		t.Errorf("empty list = %q", got)
	}
	for _, label := range []string{"", "Blue Mosque"} {
		mosque := testMosques[0]
		mosque.Label = label
		if strings.Contains(formatMosqueList(Response{mosque}), "Label:") {
			t.Errorf("redundant label %q was printed", label)
		}
	}
}

func serveAPI(t *testing.T, handler http.HandlerFunc) {
	t.Helper()
	server := httptest.NewServer(handler)
	t.Cleanup(server.Close)
	original := base
	base = server.URL
	t.Cleanup(func() { base = original })
}

func validParams() Params {
	return Params{Username: "test-user", Password: "test-password", Latitude: 52.3676, Longitude: 4.9041, Mosque: "blue-mosque"}
}

func TestValidation(t *testing.T) {
	serveAPI(t, func(w http.ResponseWriter, _ *http.Request) {
		t.Error("invalid parameters must not make a request")
		w.WriteHeader(http.StatusInternalServerError)
	})
	for _, tc := range []struct {
		name   string
		change func(*Params)
		want   string
	}{
		{"username", func(p *Params) { p.Username = "" }, "mawaqit username and password are required"},
		{"password", func(p *Params) { p.Password = "" }, "mawaqit username and password are required"},
		{"latitude", func(p *Params) { p.Latitude = 0 }, "latitude and longitude are required"},
		{"longitude", func(p *Params) { p.Longitude = 0 }, "latitude and longitude are required"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			params := validParams()
			tc.change(&params)
			data, err := New(params).GetAPI()
			if err == nil || err.Error() != tc.want || data != (shared.ApiData{}) {
				t.Fatalf("GetAPI = %+v, %v; want %q", data, err, tc.want)
			}
			if err := ListMosques(params); err == nil || err.Error() != tc.want {
				t.Fatalf("ListMosques error = %v, want %q", err, tc.want)
			}
		})
	}
}

func TestGetAPI(t *testing.T) {
	var calls atomic.Int32
	serveAPI(t, func(w http.ResponseWriter, req *http.Request) {
		calls.Add(1)
		if req.Method != http.MethodGet || req.Header.Get("Content-Type") != "application/json" {
			t.Errorf("unexpected request method or content type")
		}
		switch req.URL.Path {
		case "/me":
			user, password, ok := req.BasicAuth()
			if !ok || user != "test-user" || password != "test-password" {
				t.Error("incorrect Basic authentication")
			}
			_, _ = w.Write([]byte(`{"apiAccessToken":"test-token"}`))
		case "/mosque/search":
			if req.Header.Get("Authorization") != "test-token" {
				t.Error("search did not use the returned token")
			}
			if req.URL.Query().Get("lat") != "52.367600" || req.URL.Query().Get("lon") != "4.904100" {
				t.Errorf("coordinates = %s", req.URL.RawQuery)
			}
			if err := json.NewEncoder(w).Encode(testMosques); err != nil {
				t.Error(err)
			}
		default:
			t.Errorf("unexpected path %s", req.URL.Path)
			w.WriteHeader(http.StatusNotFound)
		}
	})
	data, err := New(validParams()).GetAPI()
	if err != nil {
		t.Fatal(err)
	}
	want := shared.ApiData{
		Timings: shared.AllTimes{Fajr: "04:30", Dhuhr: "13:36", Asr: "17:47", Maghrib: "21:24", Isha: "23:07"},
		Mosque:  &shared.MosqueInfo{UUID: "uuid-blue", Name: "Blue Mosque", Label: "المسجد الأزرق", Slug: "blue-mosque", AssociationName: "Stichting Blauw"},
	}
	if calls.Load() != 2 || !reflect.DeepEqual(data, want) {
		t.Errorf("calls = %d, data = %+v, want %+v", calls.Load(), data, want)
	}
}

func captureList(t *testing.T, params Params) (string, error) {
	t.Helper()
	file, err := os.CreateTemp(t.TempDir(), "stdout")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { file.Close() })
	original := os.Stdout
	os.Stdout = file
	defer func() { os.Stdout = original }()
	listErr := ListMosques(params)
	body, err := os.ReadFile(file.Name())
	if err != nil {
		t.Fatal(err)
	}
	return string(body), listErr
}

func TestListMosques(t *testing.T) {
	for _, tc := range []struct {
		name    string
		mosques Response
		want    string
	}{
		{"found", testMosques, "Mosques near 52.3676, 4.9041:\n\n" + formatMosqueList(testMosques)},
		{"empty", Response{}, "No mosques found near this location.\n"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			serveAPI(t, func(w http.ResponseWriter, req *http.Request) {
				if req.URL.Path == "/me" {
					_, _ = w.Write([]byte(`{"apiAccessToken":"test-token"}`))
					return
				}
				if err := json.NewEncoder(w).Encode(tc.mosques); err != nil {
					t.Error(err)
				}
			})
			params := validParams()
			params.Mosque = ""
			got, err := captureList(t, params)
			if err != nil || got != tc.want {
				t.Fatalf("output = %q, error = %v; want %q", got, err, tc.want)
			}
		})
	}
}

func TestAPIErrors(t *testing.T) {
	for _, tc := range []struct {
		name   string
		path   string
		status int
		body   string
		want   string
	}{
		{"auth status", "/me", 401, "", "auth: request returned status 401"},
		{"auth JSON", "/me", 200, "{", "auth: failed to parse response:"},
		{"search status", "/mosque/search", 503, "", "mosque search: request returned status 503"},
		{"search JSON", "/mosque/search", 200, "{", "mosque search: failed to parse response:"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			serveAPI(t, func(w http.ResponseWriter, req *http.Request) {
				if req.URL.Path == tc.path {
					w.WriteHeader(tc.status)
					_, _ = w.Write([]byte(tc.body))
					return
				}
				_, _ = w.Write([]byte(`{"apiAccessToken":"test-token"}`))
			})
			_, err := New(validParams()).GetAPI()
			if err == nil || !strings.HasPrefix(err.Error(), tc.want) {
				t.Fatalf("GetAPI error = %v, want prefix %q", err, tc.want)
			}
			output, err := captureList(t, validParams())
			if err == nil || !strings.HasPrefix(err.Error(), tc.want) || output != "" {
				t.Fatalf("ListMosques output = %q, error = %v; want prefix %q", output, err, tc.want)
			}
		})
	}
	for _, tc := range []struct {
		name    string
		mosques Response
		query   string
		want    string
	}{
		{"empty search", Response{}, "blue-mosque", "no mosques found near 52.3676, 4.9041"},
		{"missing selection", testMosques, "", "no mosque specified;"},
		{"unknown selection", testMosques, "missing", `no mosque matching "missing" found`},
		{"ambiguous selection", testMosques, "Mosque", `multiple mosques match "Mosque"`},
	} {
		t.Run(tc.name, func(t *testing.T) {
			serveAPI(t, func(w http.ResponseWriter, req *http.Request) {
				if req.URL.Path == "/me" {
					_, _ = w.Write([]byte(`{"apiAccessToken":"test-token"}`))
					return
				}
				if err := json.NewEncoder(w).Encode(tc.mosques); err != nil {
					t.Error(err)
				}
			})
			params := validParams()
			params.Mosque = tc.query
			_, err := New(params).GetAPI()
			if err == nil || !strings.HasPrefix(err.Error(), tc.want) {
				t.Fatalf("error = %v, want prefix %q", err, tc.want)
			}
		})
	}
}
