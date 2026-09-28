package shared

import (
	"errors"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
	"time"
)

func TestOrderedTimings(t *testing.T) {
	want := []namedTime{{"Fajr", "04:00"}, {"Dhuhr", "13:00"}, {"Asr", "17:00"}, {"Maghrib", "21:00"}, {"Isha", "23:00"}}
	if got := orderedTimings(validTimes); !reflect.DeepEqual(got, want) {
		t.Errorf("ordered timings = %+v, want %+v", got, want)
	}
}

func TestGetPrayerTime(t *testing.T) {
	got, err := getPrayerTime("06 Jul 2026 13:00")
	want := time.Date(2026, time.July, 6, 13, 0, 0, 0, time.Local)
	if err != nil || !got.Equal(want) || got.Location() != time.Local {
		t.Fatalf("time = %s, error = %v, want %s in local timezone", got, err, want)
	}
	if _, err := getPrayerTime("not a time"); err == nil {
		t.Error("invalid time accepted")
	}
}

func TestCacheInvalidation(t *testing.T) {
	t.Setenv("TMPDIR", t.TempDir())
	source := &fakeSource{data: ApiData{Timings: validTimes}}
	key := CacheKey{Source: "aladhan", Variant: "method=3", City: "Amsterdam", Country: "NL"}
	cases := []struct {
		key CacheKey
		now time.Time
	}{
		{key, testNow},
		{CacheKey{Source: "aladhan", Variant: "method=0", City: key.City, Country: key.Country}, testNow},
		{CacheKey{Source: "aladhan", Variant: key.Variant, City: "Delft", Country: key.Country}, testNow},
		{key, testNow.AddDate(0, 0, 1)},
	}
	for i, tc := range cases {
		if _, err := getData(source, tc.key, tc.now); err != nil {
			t.Fatal(err)
		}
		if source.calls != i+1 {
			t.Fatalf("case %d: API calls = %d, want %d", i, source.calls, i+1)
		}
	}
}

func TestDataErrors(t *testing.T) {
	t.Setenv("TMPDIR", t.TempDir())
	key := CacheKey{Source: "test"}
	failure := errors.New("provider unavailable")
	source := &fakeSource{err: failure}
	if _, err := GetSchedule(source, key); !errors.Is(err, failure) {
		t.Fatalf("schedule error = %v, want provider error", err)
	}
	if _, err := GetPrayer(source, key); !errors.Is(err, failure) {
		t.Fatalf("prayer error = %v, want provider error", err)
	}
	entries, err := os.ReadDir(os.TempDir())
	if err != nil || len(entries) != 0 {
		t.Fatalf("failed fetch left cache entries: %v, error %v", entries, err)
	}

	cache := filepath.Join(os.TempDir(), cacheFilename(key, testNow))
	if err := os.Mkdir(cache, 0700); err != nil {
		t.Fatal(err)
	}
	source = &fakeSource{data: ApiData{Timings: validTimes}}
	if _, err := getData(source, key, testNow); err == nil || !strings.HasPrefix(err.Error(), "failed to write cache ") {
		t.Fatalf("error = %v, want cache write failure", err)
	}
}

func TestGetPrayerAfterIsha(t *testing.T) {
	t.Setenv("TMPDIR", t.TempDir())
	source := &fakeSource{data: ApiData{Timings: AllTimes{Fajr: "04:00", Dhuhr: "00:00", Asr: "00:00", Maghrib: "00:00", Isha: "00:00"}}}
	got, err := GetPrayer(source, CacheKey{Source: "test"})
	want := Output{Item: "Fajr: 04:00", TimeRemaining: -1}
	if err != nil || got != want {
		t.Fatalf("prayer = %+v, error = %v, want %+v", got, err, want)
	}
}

func TestGetPrayerUpcoming(t *testing.T) {
	t.Setenv("TMPDIR", t.TempDir())
	source := &fakeSource{data: ApiData{Timings: AllTimes{Fajr: "23:59", Dhuhr: "23:59", Asr: "23:59", Maghrib: "23:59", Isha: "23:59"}}}
	before := time.Now()
	got, err := GetPrayer(source, CacheKey{Source: "test"})
	after := time.Now()
	if err != nil || got.Item != "Fajr: 23:59" {
		t.Fatalf("prayer = %+v, error = %v", got, err)
	}
	end := time.Date(before.Year(), before.Month(), before.Day(), 23, 59, 0, 0, time.Local)
	if after.Before(end) {
		min, max := int(end.Sub(after).Minutes()), int(end.Sub(before).Minutes())
		if got.TimeRemaining < min || got.TimeRemaining > max {
			t.Errorf("remaining = %d, want between %d and %d", got.TimeRemaining, min, max)
		}
	} else if before.After(end) && got.TimeRemaining != -1 {
		t.Errorf("after Isha remaining = %d, want -1", got.TimeRemaining)
	}
}
