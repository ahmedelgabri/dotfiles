package shared

import (
	"errors"
	"os"
	"path/filepath"
	"testing"
	"time"
)

var testNow = time.Date(2026, time.July, 6, 12, 0, 0, 0, time.UTC)

var validTimes = AllTimes{
	Fajr:    "04:00",
	Dhuhr:   "13:00",
	Asr:     "17:00",
	Maghrib: "21:00",
	Isha:    "23:00",
}

func TestCacheFilename(t *testing.T) {
	cases := []struct {
		name string
		key  CacheKey
		want string
	}{
		{
			name: "source only",
			key:  CacheKey{Source: "mawaqit"},
			want: ".prayer-mawaqit_06-07-2026.json",
		},
		{
			name: "source and location",
			key:  CacheKey{Source: "aladhan", City: "Amsterdam", Country: "NL"},
			want: ".prayer-aladhan_amsterdam_nl_06-07-2026.json",
		},
		{
			name: "source, mosque, and location",
			key:  CacheKey{Source: "mawaqit", Mosque: "Blue Mosque", City: "Amsterdam", Country: "NL"},
			want: ".prayer-mawaqit_blue-mosque_amsterdam_nl_06-07-2026.json",
		},
		{
			name: "partial location keeps both parts",
			key:  CacheKey{Source: "mawaqit", City: "Amsterdam"},
			want: ".prayer-mawaqit_amsterdam__06-07-2026.json",
		},
		{
			name: "slashes and whitespace are sanitized",
			key:  CacheKey{Source: "mawaqit", Mosque: " Masjid/Foo ", City: "Den Haag", Country: "NL"},
			want: ".prayer-mawaqit_masjid-foo_den-haag_nl_06-07-2026.json",
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got := cacheFilename(tc.key, testNow)
			if got != tc.want {
				t.Errorf("cacheFilename(%+v) = %q, want %q", tc.key, got, tc.want)
			}
		})
	}
}

func TestValidateTimings(t *testing.T) {
	if err := validateTimings(validTimes); err != nil {
		t.Errorf("valid timings rejected: %v", err)
	}

	missing := validTimes
	missing.Maghrib = ""
	if err := validateTimings(missing); err == nil {
		t.Error("empty Maghrib accepted")
	}

	garbage := validTimes
	garbage.Fajr = "not a time"
	if err := validateTimings(garbage); err == nil {
		t.Error("unparseable Fajr accepted")
	}
}

func TestReadCache(t *testing.T) {
	dir := t.TempDir()

	if _, ok := readCache(filepath.Join(dir, "missing.json")); ok {
		t.Error("missing file treated as a hit")
	}

	corrupt := filepath.Join(dir, "corrupt.json")
	if err := os.WriteFile(corrupt, []byte("{not json"), 0644); err != nil {
		t.Fatal(err)
	}
	if _, ok := readCache(corrupt); ok {
		t.Error("corrupt JSON treated as a hit")
	}

	invalid := filepath.Join(dir, "invalid.json")
	if err := os.WriteFile(invalid, []byte(`{"timings":{"fajr":""}}`), 0644); err != nil {
		t.Fatal(err)
	}
	if _, ok := readCache(invalid); ok {
		t.Error("invalid timings treated as a hit")
	}

	valid := filepath.Join(dir, "valid.json")
	body := `{"timings":{"fajr":"04:00","dhuhr":"13:00","asr":"17:00","maghrib":"21:00","isha":"23:00"}}`
	if err := os.WriteFile(valid, []byte(body), 0644); err != nil {
		t.Fatal(err)
	}
	data, ok := readCache(valid)
	if !ok {
		t.Fatal("valid cache treated as a miss")
	}
	if data.Timings != validTimes {
		t.Errorf("readCache returned %+v, want %+v", data.Timings, validTimes)
	}
}

type fakeSource struct {
	data  ApiData
	err   error
	calls int
}

func (f *fakeSource) GetAPI() (ApiData, error) {
	f.calls++
	return f.data, f.err
}

func TestGetData(t *testing.T) {
	key := CacheKey{Source: "test", City: "Amsterdam", Country: "NL"}

	t.Run("fetches, caches, then reuses the cache", func(t *testing.T) {
		t.Setenv("TMPDIR", t.TempDir())
		source := &fakeSource{data: ApiData{Timings: validTimes}}

		if _, err := getData(source, key, testNow); err != nil {
			t.Fatalf("first getData failed: %v", err)
		}
		if _, err := getData(source, key, testNow); err != nil {
			t.Fatalf("second getData failed: %v", err)
		}
		if source.calls != 1 {
			t.Errorf("API called %d times, want 1", source.calls)
		}
	})

	t.Run("invalid API data is not cached", func(t *testing.T) {
		t.Setenv("TMPDIR", t.TempDir())
		source := &fakeSource{data: ApiData{}}

		if _, err := getData(source, key, testNow); err == nil {
			t.Fatal("invalid API data accepted")
		}

		cache := filepath.Join(os.TempDir(), cacheFilename(key, testNow))
		if _, err := os.Stat(cache); !errors.Is(err, os.ErrNotExist) {
			t.Errorf("invalid data was written to the cache: %v", err)
		}
	})

	t.Run("corrupt cache is refetched and rewritten", func(t *testing.T) {
		t.Setenv("TMPDIR", t.TempDir())
		cache := filepath.Join(os.TempDir(), cacheFilename(key, testNow))
		if err := os.WriteFile(cache, []byte("{not json"), 0644); err != nil {
			t.Fatal(err)
		}

		source := &fakeSource{data: ApiData{Timings: validTimes}}
		data, err := getData(source, key, testNow)
		if err != nil {
			t.Fatalf("getData failed on corrupt cache: %v", err)
		}
		if source.calls != 1 {
			t.Errorf("API called %d times, want 1", source.calls)
		}
		if data.Timings != validTimes {
			t.Errorf("getData returned %+v, want %+v", data.Timings, validTimes)
		}
		if _, ok := readCache(cache); !ok {
			t.Error("cache was not rewritten with valid data")
		}
	})
}
