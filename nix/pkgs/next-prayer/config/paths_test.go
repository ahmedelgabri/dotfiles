package config

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestConfigPath(t *testing.T) {
	home, xdg := t.TempDir(), t.TempDir()
	t.Setenv("HOME", home)
	t.Setenv("XDG_CONFIG_HOME", xdg)
	if got := configPath("explicit.toml"); got != "explicit.toml" {
		t.Errorf("explicit config path = %q", got)
	}
	if got, want := configPath(""), filepath.Join(xdg, "prayer-times", "config.toml"); got != want {
		t.Errorf("XDG path = %q, want %q", got, want)
	}
	t.Setenv("XDG_CONFIG_HOME", "")
	if got, want := configPath(""), filepath.Join(home, ".config", "prayer-times", "config.toml"); got != want {
		t.Errorf("home path = %q, want %q", got, want)
	}
	t.Setenv("HOME", "")
	cfg, err := Load("")
	if err != nil || cfg != (Config{}) {
		t.Fatalf("without HOME or XDG_CONFIG_HOME: config = %+v, error = %v", cfg, err)
	}
}

func TestLoadDefaultConfig(t *testing.T) {
	root := t.TempDir()
	t.Setenv("XDG_CONFIG_HOME", root)
	dir := filepath.Join(root, "prayer-times")
	if err := os.MkdirAll(dir, 0700); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "config.toml"), []byte("[aladhan]\ncity='Amsterdam'\ncountry='NL'\n"), 0600); err != nil {
		t.Fatal(err)
	}
	cfg, err := Load("")
	if err != nil || cfg.Aladhan.City != "Amsterdam" || cfg.Aladhan.Country != "NL" || cfg.Aladhan.Method != nil {
		t.Fatalf("config = %+v, error = %v", cfg, err)
	}
}

func TestLoadErrors(t *testing.T) {
	for _, body := range []string{"[broken", "[aladhan]\nmethod='not-an-integer'\n"} {
		path := filepath.Join(t.TempDir(), "config.toml")
		if err := os.WriteFile(path, []byte(body), 0600); err != nil {
			t.Fatal(err)
		}
		if _, err := Load(path); err == nil || !strings.HasPrefix(err.Error(), "failed to load config "+path+":") {
			t.Fatalf("error = %v, want config parse error", err)
		}
	}
	if _, err := Load(t.TempDir()); err == nil {
		t.Error("a directory must not be treated as a missing config file")
	}
}

func TestResolveUnsetValues(t *testing.T) {
	t.Setenv("TEST_UNSET", "")
	if got := ResolveFloat64(0, 0, "TEST_UNSET"); got != 0 {
		t.Errorf("unset float = %v", got)
	}
	if got := ResolveInt(-1, nil, "TEST_UNSET"); got != -1 {
		t.Errorf("unset integer = %d", got)
	}
	t.Setenv("TEST_UNSET", "0")
	if got := ResolveInt(-1, nil, "TEST_UNSET"); got != 0 {
		t.Errorf("environment method zero = %d", got)
	}
}
