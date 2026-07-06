package config

import (
	"os"
	"path/filepath"
	"testing"
)

func TestResolveString(t *testing.T) {
	t.Setenv("TEST_RESOLVE_STRING", "from-env")

	if got := ResolveString("from-flag", "from-config", "TEST_RESOLVE_STRING"); got != "from-flag" {
		t.Errorf("flag should win, got %q", got)
	}
	if got := ResolveString("", "from-config", "TEST_RESOLVE_STRING"); got != "from-config" {
		t.Errorf("config should win over env, got %q", got)
	}
	if got := ResolveString("", "", "TEST_RESOLVE_STRING"); got != "from-env" {
		t.Errorf("env should be the fallback, got %q", got)
	}
	if got := ResolveString("", "", "TEST_RESOLVE_STRING_UNSET"); got != "" {
		t.Errorf("unresolved should be empty, got %q", got)
	}
}

func TestResolveFloat64(t *testing.T) {
	t.Setenv("TEST_RESOLVE_FLOAT", "4.9041")
	t.Setenv("TEST_RESOLVE_FLOAT_BAD", "not-a-float")

	if got := ResolveFloat64(52.3676, 1.0, "TEST_RESOLVE_FLOAT"); got != 52.3676 {
		t.Errorf("flag should win, got %v", got)
	}
	if got := ResolveFloat64(0, 1.0, "TEST_RESOLVE_FLOAT"); got != 1.0 {
		t.Errorf("config should win over env, got %v", got)
	}
	if got := ResolveFloat64(0, 0, "TEST_RESOLVE_FLOAT"); got != 4.9041 {
		t.Errorf("env should be the fallback, got %v", got)
	}
	if got := ResolveFloat64(0, 0, "TEST_RESOLVE_FLOAT_BAD"); got != 0 {
		t.Errorf("bad env value should resolve to 0, got %v", got)
	}
}

func TestResolveInt(t *testing.T) {
	t.Setenv("TEST_RESOLVE_INT", "12")
	t.Setenv("TEST_RESOLVE_INT_BAD", "not-an-int")
	three := 3

	if got := ResolveInt(5, &three, "TEST_RESOLVE_INT"); got != 5 {
		t.Errorf("flag should win, got %d", got)
	}
	if got := ResolveInt(0, &three, "TEST_RESOLVE_INT"); got != 0 {
		t.Errorf("flag value 0 should be respected, got %d", got)
	}
	if got := ResolveInt(-1, &three, "TEST_RESOLVE_INT"); got != 3 {
		t.Errorf("config should win over env, got %d", got)
	}
	zero := 0
	if got := ResolveInt(-1, &zero, "TEST_RESOLVE_INT"); got != 0 {
		t.Errorf("config value 0 should be respected, got %d", got)
	}
	if got := ResolveInt(-1, nil, "TEST_RESOLVE_INT"); got != 12 {
		t.Errorf("env should be the fallback, got %d", got)
	}
	if got := ResolveInt(-1, nil, "TEST_RESOLVE_INT_BAD"); got != -1 {
		t.Errorf("bad env value should resolve to -1, got %d", got)
	}
	if got := ResolveInt(-1, nil, "TEST_RESOLVE_INT_UNSET"); got != -1 {
		t.Errorf("unresolved should be -1, got %d", got)
	}
}

func TestLoad(t *testing.T) {
	t.Run("missing file is not an error", func(t *testing.T) {
		cfg, err := Load(filepath.Join(t.TempDir(), "missing.toml"))
		if err != nil {
			t.Fatalf("missing config file should not error: %v", err)
		}
		if cfg != (Config{}) {
			t.Errorf("missing config should be empty, got %+v", cfg)
		}
	})

	t.Run("explicit path override", func(t *testing.T) {
		path := filepath.Join(t.TempDir(), "config.toml")
		body := `
[mawaqit]
latitude = 52.3676
mosque = "blue-mosque"

[aladhan]
city = "Amsterdam"
method = 0
`
		if err := os.WriteFile(path, []byte(body), 0644); err != nil {
			t.Fatal(err)
		}

		cfg, err := Load(path)
		if err != nil {
			t.Fatalf("Load failed: %v", err)
		}
		if cfg.Mawaqit.Latitude != 52.3676 || cfg.Mawaqit.Mosque != "blue-mosque" {
			t.Errorf("unexpected mawaqit config: %+v", cfg.Mawaqit)
		}
		if cfg.Aladhan.City != "Amsterdam" {
			t.Errorf("unexpected aladhan config: %+v", cfg.Aladhan)
		}
		if cfg.Aladhan.Method == nil || *cfg.Aladhan.Method != 0 {
			t.Errorf("method 0 should decode as set, got %v", cfg.Aladhan.Method)
		}
	})
}
