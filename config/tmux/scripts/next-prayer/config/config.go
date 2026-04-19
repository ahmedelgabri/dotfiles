package config

import (
	"fmt"
	"os"
	"path/filepath"
	"strconv"

	"github.com/BurntSushi/toml"
)

type MawaqitConfig struct {
	Username  string  `toml:"username"`
	Password  string  `toml:"password"`
	Latitude  float64 `toml:"latitude"`
	Longitude float64 `toml:"longitude"`
	Mosque    string  `toml:"mosque"`
}

type AladhanConfig struct {
	City    string `toml:"city"`
	Country string `toml:"country"`
	Method  int    `toml:"method"`
	Tune    string `toml:"tune"`
}

type Config struct {
	Mawaqit MawaqitConfig `toml:"mawaqit"`
	Aladhan AladhanConfig `toml:"aladhan"`
}

func configPath(override string) string {
	if override != "" {
		return override
	}

	xdgConfig := os.Getenv("XDG_CONFIG_HOME")
	if xdgConfig == "" {
		home, err := os.UserHomeDir()
		if err != nil {
			return ""
		}
		xdgConfig = filepath.Join(home, ".config")
	}

	return filepath.Join(xdgConfig, "prayer-times", "config.toml")
}

func Load(path string) (Config, error) {
	p := configPath(path)
	if p == "" {
		return Config{}, nil
	}

	var cfg Config
	_, err := toml.DecodeFile(p, &cfg)
	if err != nil {
		if os.IsNotExist(err) {
			return Config{}, nil
		}
		return Config{}, fmt.Errorf("failed to load config %s: %w", p, err)
	}

	return cfg, nil
}

// ResolveString returns the first non-empty value from: flag, config, env var.
func ResolveString(flag string, cfgVal string, envKey string) string {
	if flag != "" {
		return flag
	}
	if cfgVal != "" {
		return cfgVal
	}
	return os.Getenv(envKey)
}

// ResolveFloat64 returns the first non-zero value from: flag, config, env var.
func ResolveFloat64(flag float64, cfgVal float64, envKey string) float64 {
	if flag != 0 {
		return flag
	}
	if cfgVal != 0 {
		return cfgVal
	}
	s := os.Getenv(envKey)
	if s == "" {
		return 0
	}
	v, err := strconv.ParseFloat(s, 64)
	if err != nil {
		return 0
	}
	return v
}

// ResolveInt returns the first non-zero value from: flag, config, env var.
func ResolveInt(flag int, cfgVal int, envKey string) int {
	if flag != 0 {
		return flag
	}
	if cfgVal != 0 {
		return cfgVal
	}
	s := os.Getenv(envKey)
	if s == "" {
		return 0
	}
	v, err := strconv.Atoi(s)
	if err != nil {
		return 0
	}
	return v
}
