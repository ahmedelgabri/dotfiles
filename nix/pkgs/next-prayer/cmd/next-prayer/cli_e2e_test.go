//go:build e2e

package main

import (
	"os"
	"regexp"
	"strings"
	"testing"
	"time"

	"github.com/ahmedelgabri/dotfiles/config/tmux/scripts/next-prayer/shared"
)

func requireLiveSuccess(t *testing.T, result cliResult) string {
	t.Helper()
	if result.code != 0 || result.stderr != "" {
		message := result.stderr
		for _, key := range []string{"MAWAQIT_USERNAME", "MAWAQIT_PASSWORD"} {
			if value := os.Getenv(key); value != "" {
				message = strings.ReplaceAll(message, value, "[redacted]")
			}
		}
		t.Fatalf("live CLI exit = %d, stderr = %q", result.code, message)
	}
	return result.stdout
}

func validateLiveSchedule(t *testing.T, schedule shared.Schedule, provider string, started time.Time) {
	t.Helper()
	if schedule.Source != provider {
		t.Errorf("source = %q, want %q", schedule.Source, provider)
	}
	if schedule.Date != started.Format("2006-01-02") && schedule.Date != time.Now().Format("2006-01-02") {
		t.Errorf("schedule is not for today: %q", schedule.Date)
	}
	for name, value := range map[string]string{
		"Fajr": schedule.Timings.Fajr, "Dhuhr": schedule.Timings.Dhuhr,
		"Asr": schedule.Timings.Asr, "Maghrib": schedule.Timings.Maghrib, "Isha": schedule.Timings.Isha,
	} {
		if _, err := time.Parse("15:04", value); err != nil {
			t.Errorf("invalid %s time: %q", name, value)
		}
	}
}

func TestLiveCLI(t *testing.T) {
	for _, key := range []string{"MAWAQIT_USERNAME", "MAWAQIT_PASSWORD"} {
		if os.Getenv(key) == "" {
			t.Fatalf("%s must be set to run the live suite", key)
		}
	}
	binary := buildCLI(t)
	for _, provider := range []string{"aladhan", "mawaqit"} {
		t.Run(provider, func(t *testing.T) {
			env := cliEnvironment(t)
			args := []string{provider}
			var mosqueID string
			if provider == "aladhan" {
				args = append(args, "--city", "Amsterdam", "--country", "NL", "--method", "3")
			} else {
				env = append(env, "MAWAQIT_USERNAME="+os.Getenv("MAWAQIT_USERNAME"), "MAWAQIT_PASSWORD="+os.Getenv("MAWAQIT_PASSWORD"))
				args = append(args, "--latitude", "52.3676", "--longitude", "4.9041")
				listing := requireLiveSuccess(t, runCLI(t, binary, env, append(args, "--list-mosques")...))
				match := regexp.MustCompile(`(?m)^  UUID:    (\S+)$`).FindStringSubmatch(listing)
				if match == nil {
					t.Fatal("live mosque listing returned no UUID near Amsterdam")
				}
				mosqueID = match[1]
				args = append(args, "--mosque", mosqueID)
			}
			started := time.Now()
			output := requireLiveSuccess(t, runCLI(t, binary, env, append(args, "--json")...))
			schedule := decodeSchedule(t, output)
			validateLiveSchedule(t, schedule, provider, started)
			if provider == "mawaqit" {
				if schedule.Mosque == nil || schedule.Mosque.UUID != mosqueID || schedule.Mosque.Name == "" {
					t.Fatal("live schedule did not retain the selected mosque's identity")
				}
			} else if schedule.Mosque != nil || strings.Contains(output, `"mosque"`) {
				t.Error("Aladhan schedule contains mosque metadata")
			}

			// The cache must work without another API call, using the real response above.
			env = append(env, "HTTPS_PROXY=http://127.0.0.1:0", "HTTP_PROXY=http://127.0.0.1:0", "NO_PROXY=")
			cached := requireLiveSuccess(t, runCLI(t, binary, env, append(args, "--json")...))
			if cached != output {
				t.Error("cached schedule differs from the live response")
			}
			text := requireLiveSuccess(t, runCLI(t, binary, env, args...))
			text = strings.TrimSpace(strings.NewReplacer("\033[1;31;40m", "", "\033[0m", "").Replace(text))
			matched := false
			for name, value := range map[string]string{
				"Fajr": schedule.Timings.Fajr, "Dhuhr": schedule.Timings.Dhuhr,
				"Asr": schedule.Timings.Asr, "Maghrib": schedule.Timings.Maghrib, "Isha": schedule.Timings.Isha,
			} {
				matched = matched || text == name+": "+value
			}
			if !matched {
				t.Error("next-prayer text does not match a time in the live schedule")
			}
		})
	}
}
