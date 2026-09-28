package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
	"time"

	"github.com/ahmedelgabri/dotfiles/config/tmux/scripts/next-prayer/shared"
)

func buildCLI(t *testing.T) string {
	t.Helper()
	binary := filepath.Join(t.TempDir(), "next-prayer")
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	cmd := exec.CommandContext(ctx, "go", "build", "-ldflags=-X main.version=test-version", "-o", binary, ".")
	if output, err := cmd.CombinedOutput(); err != nil {
		t.Fatalf("build CLI: %v\n%s", err, output)
	}
	return binary
}

func cliEnvironment(t *testing.T) []string {
	t.Helper()
	var env []string
	for _, entry := range os.Environ() {
		key, _, _ := strings.Cut(entry, "=")
		if strings.HasPrefix(key, "MAWAQIT_") || strings.HasPrefix(key, "ALADHAN_") {
			continue
		}
		switch key {
		case "HOME", "XDG_CONFIG_HOME", "TMPDIR", "TMP", "TEMP", "TMUX":
			continue
		}
		env = append(env, entry)
	}
	home, cache := t.TempDir(), t.TempDir()
	return append(env, "HOME="+home, "XDG_CONFIG_HOME="+home, "TMPDIR="+cache, "TMP="+cache, "TEMP="+cache)
}

type cliResult struct {
	stdout string
	stderr string
	code   int
}

func runCLI(t *testing.T, binary string, env []string, args ...string) cliResult {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 45*time.Second)
	defer cancel()
	cmd := exec.CommandContext(ctx, binary, args...)
	cmd.Env = env
	var stdout, stderr bytes.Buffer
	cmd.Stdout, cmd.Stderr = &stdout, &stderr
	err := cmd.Run()
	if ctx.Err() != nil {
		t.Fatal("CLI exceeded its deadline")
	}
	var exit *exec.ExitError
	if err != nil && !errors.As(err, &exit) {
		t.Fatalf("start CLI: %v", err)
	}
	return cliResult{stdout.String(), stderr.String(), cmd.ProcessState.ExitCode()}
}

func decodeSchedule(t *testing.T, text string) shared.Schedule {
	t.Helper()
	decoder := json.NewDecoder(strings.NewReader(text))
	decoder.DisallowUnknownFields()
	var schedule shared.Schedule
	if err := decoder.Decode(&schedule); err != nil {
		t.Fatalf("decode schedule: %v", err)
	}
	if err := decoder.Decode(new(any)); err != io.EOF {
		t.Fatal("expected exactly one JSON object on stdout")
	}
	return schedule
}

func TestCLI(t *testing.T) {
	binary := buildCLI(t)
	for _, tc := range []struct {
		name   string
		args   []string
		code   int
		stdout string
		stderr string
	}{
		{"help", []string{"--help"}, 0, "next-prayer <command>", ""},
		{"version", []string{"--version"}, 0, "test-version\n", ""},
		{"no command", nil, 1, "next-prayer <command>", ""},
		{"unknown command", []string{"missing"}, 1, "next-prayer <command>", "unknown command: missing\n"},
		{"unknown flag", []string{"--missing"}, 2, "", "flag provided but not defined: -missing"},
		{"aladhan help", []string{"aladhan", "--help"}, 0, "next-prayer aladhan", ""},
		{"mawaqit help", []string{"mawaqit", "--help"}, 0, "next-prayer mawaqit", ""},
		{"invalid method", []string{"aladhan", "--method", "invalid"}, 2, "", "invalid value"},
		{"missing flag value", []string{"aladhan", "--city"}, 2, "", "flag needs an argument: -city"},
		{"missing city", []string{"aladhan"}, 1, "", "error: aladhan city is required\n"},
		{"missing country", []string{"aladhan", "--city", "Amsterdam"}, 1, "", "error: aladhan country is required\n"},
		{"missing method", []string{"aladhan", "--city", "Amsterdam", "--country", "NL"}, 1, "", "error: aladhan method is required\n"},
		{"missing credentials", []string{"mawaqit"}, 1, "", "error: mawaqit username and password are required\n"},
		{"list missing credentials", []string{"mawaqit", "--list-mosques"}, 1, "", "error: mawaqit username and password are required\n"},
		{"missing coordinates", []string{"mawaqit", "--username", "test-user", "--password", "test-password"}, 1, "", "error: latitude and longitude are required\n"},
		{"JSON error", []string{"aladhan", "--json"}, 1, "", "error: aladhan city is required\n"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			env := append(cliEnvironment(t), "HTTPS_PROXY=http://127.0.0.1:0", "HTTP_PROXY=http://127.0.0.1:0", "NO_PROXY=")
			got := runCLI(t, binary, env, tc.args...)
			if got.code != tc.code {
				t.Fatalf("exit = %d, want %d; stderr = %q", got.code, tc.code, got.stderr)
			}
			if (tc.stdout == "" && got.stdout != "") || !strings.Contains(got.stdout, tc.stdout) {
				t.Errorf("stdout = %q, want %q", got.stdout, tc.stdout)
			}
			if (tc.stderr == "" && got.stderr != "") || !strings.HasPrefix(got.stderr, tc.stderr) {
				t.Errorf("stderr = %q, want prefix %q", got.stderr, tc.stderr)
			}
		})
	}
	for _, provider := range []string{"aladhan", "mawaqit"} {
		t.Run(provider+" config error", func(t *testing.T) {
			path := filepath.Join(t.TempDir(), "invalid.toml")
			if err := os.WriteFile(path, []byte("[broken"), 0600); err != nil {
				t.Fatal(err)
			}
			env := cliEnvironment(t)
			got := runCLI(t, binary, env, provider, "--config", path)
			if got.code != 1 || got.stdout != "" || !strings.HasPrefix(got.stderr, "error: failed to load config "+path) {
				t.Fatalf("unexpected result: %+v", got)
			}
			got = runCLI(t, binary, env, provider, "--config", path, "--help")
			if got.code != 0 || got.stderr != "" || !strings.Contains(got.stdout, "Usage") {
				t.Fatalf("help should not load config: %+v", got)
			}
		})
	}
}

type cachedSource struct {
	data shared.ApiData
}

func (s cachedSource) GetAPI() (shared.ApiData, error) { return s.data, nil }

func TestCLICachedSchedule(t *testing.T) {
	binary := buildCLI(t)
	timings := shared.AllTimes{Fajr: "00:00", Dhuhr: "00:00", Asr: "00:00", Maghrib: "00:00", Isha: "00:00"}
	for _, provider := range []string{"aladhan", "mawaqit"} {
		t.Run(provider, func(t *testing.T) {
			env := append(cliEnvironment(t), "HTTPS_PROXY=http://127.0.0.1:0", "HTTP_PROXY=http://127.0.0.1:0", "NO_PROXY=")
			for _, entry := range env {
				if value, ok := strings.CutPrefix(entry, "TMPDIR="); ok {
					t.Setenv("TMPDIR", value)
				}
			}
			key := shared.CacheKey{Source: provider, City: "Amsterdam", Country: "NL"}
			data := shared.ApiData{Timings: timings}
			var configBody string
			if provider == "aladhan" {
				key.Variant = "method=0&tune=0,0,0"
				configBody = "[aladhan]\ncity='Amsterdam'\ncountry='NL'\nmethod=0\ntune='0,0,0'\n"
			} else {
				key.Variant, key.Mosque = "lat=52.3676&lon=4.9041", "test-mosque"
				data.Mosque = &shared.MosqueInfo{UUID: "test-uuid", Name: "Test Mosque", Slug: key.Mosque}
				configBody = "[mawaqit]\nlatitude=52.3676\nlongitude=4.9041\nmosque='test-mosque'\n"
			}
			want, err := shared.GetSchedule(cachedSource{data}, key)
			if err != nil {
				t.Fatal(err)
			}
			configPath := filepath.Join(t.TempDir(), "config.toml")
			if err := os.WriteFile(configPath, []byte(configBody), 0600); err != nil {
				t.Fatal(err)
			}
			args := []string{provider, "--config", configPath, "--city", key.City, "--country", key.Country}
			result := runCLI(t, binary, env, append(args, "--json")...)
			if result.code != 0 || result.stderr != "" {
				t.Fatalf("cached JSON failed: %+v", result)
			}
			if got := decodeSchedule(t, result.stdout); !reflect.DeepEqual(got, want) {
				t.Errorf("schedule = %+v, want %+v", got, want)
			}
			if provider == "aladhan" && strings.Contains(result.stdout, `"mosque"`) {
				t.Error("Aladhan JSON must omit mosque metadata")
			}
			result = runCLI(t, binary, env, args...)
			if result.code != 0 || result.stderr != "" || result.stdout != "Fajr: 00:00\n" {
				t.Fatalf("cached text failed: %+v", result)
			}
		})
	}
}
