package aladhan

import (
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"sync/atomic"
	"testing"

	"github.com/ahmedelgabri/dotfiles/config/tmux/scripts/next-prayer/shared"
)

type roundTripFunc func(*http.Request) (*http.Response, error)

func (f roundTripFunc) RoundTrip(req *http.Request) (*http.Response, error) {
	return f(req)
}

func routeAPI(t *testing.T, handler http.HandlerFunc) {
	t.Helper()
	server := httptest.NewServer(handler)
	t.Cleanup(server.Close)
	target, err := url.Parse(server.URL)
	if err != nil {
		t.Fatal(err)
	}
	original := http.DefaultTransport
	t.Cleanup(func() { http.DefaultTransport = original })
	http.DefaultTransport = roundTripFunc(func(req *http.Request) (*http.Response, error) {
		if req.URL.Scheme != "https" || req.URL.Host != "api.aladhan.com" {
			t.Errorf("unexpected API endpoint: %s", req.URL)
		}
		copy := req.Clone(req.Context())
		copy.URL.Scheme, copy.URL.Host = target.Scheme, target.Host
		return original.RoundTrip(copy)
	})
}

func TestGetAPIValidation(t *testing.T) {
	routeAPI(t, func(w http.ResponseWriter, _ *http.Request) {
		t.Error("invalid parameters must not make a request")
		w.WriteHeader(http.StatusInternalServerError)
	})
	for _, tc := range []struct {
		name   string
		params Params
		want   string
	}{
		{"missing city", Params{Country: "NL", Method: 3}, "aladhan city is required"},
		{"missing country", Params{City: "Amsterdam", Method: 3}, "aladhan country is required"},
		{"missing method", Params{City: "Amsterdam", Country: "NL", Method: -1}, "aladhan method is required"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			data, err := New(tc.params).GetAPI()
			if err == nil || err.Error() != tc.want {
				t.Fatalf("error = %v, want %q", err, tc.want)
			}
			if data != (shared.ApiData{}) {
				t.Errorf("failed request returned data: %+v", data)
			}
		})
	}
}

func TestGetAPI(t *testing.T) {
	params := Params{City: "Den Haag & Delft", Country: "NL", Method: 0, Tune: "0,-18,0,0,0,0,0,12,0"}
	want := shared.AllTimes{Fajr: "04:30", Dhuhr: "13:36", Asr: "17:47", Maghrib: "21:24", Isha: "23:07"}
	var calls atomic.Int32
	routeAPI(t, func(w http.ResponseWriter, req *http.Request) {
		calls.Add(1)
		if req.Method != http.MethodGet || req.URL.Path != "/v1/timingsByCity" {
			t.Errorf("request = %s %s", req.Method, req.URL.Path)
		}
		query := req.URL.Query()
		for key, value := range map[string]string{"city": params.City, "country": params.Country, "method": "0", "tune": params.Tune} {
			if query.Get(key) != value {
				t.Errorf("query %s = %q, want %q", key, query.Get(key), value)
			}
		}
		if req.UserAgent() == "" {
			t.Error("missing User-Agent")
		}
		_, _ = w.Write([]byte(`{"code":200,"status":"OK","data":{"timings":{"Fajr":"04:30","Dhuhr":"13:36","Asr":"17:47","Maghrib":"21:24","Isha":"23:07","Sunrise":"06:00"},"date":{"readable":"01 Aug 2026"}}}`))
	})
	data, err := New(params).GetAPI()
	if err != nil {
		t.Fatal(err)
	}
	if calls.Load() != 1 || data.Timings != want || data.Mosque != nil {
		t.Errorf("calls = %d, data = %+v, want timings %+v and no mosque", calls.Load(), data, want)
	}
}

func TestGetAPIErrors(t *testing.T) {
	for _, tc := range []struct {
		name   string
		status int
		body   string
		want   string
	}{
		{"HTTP status", 503, `unavailable`, "aladhan API: request returned status 503"},
		{"invalid JSON", 200, `{`, "aladhan API: failed to parse response:"},
		{"API status", 200, `{"code":400,"status":"Invalid city"}`, "aladhan API returned code 400: Invalid city"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			routeAPI(t, func(w http.ResponseWriter, _ *http.Request) {
				w.WriteHeader(tc.status)
				_, _ = w.Write([]byte(tc.body))
			})
			data, err := New(Params{City: "Amsterdam", Country: "NL", Method: 3}).GetAPI()
			if err == nil || !strings.HasPrefix(err.Error(), tc.want) {
				t.Fatalf("error = %v, want prefix %q", err, tc.want)
			}
			if data != (shared.ApiData{}) {
				t.Errorf("failed request returned data: %+v", data)
			}
		})
	}
}
