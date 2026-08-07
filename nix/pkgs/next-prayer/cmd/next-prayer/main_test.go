package main

import (
	"os"
	"testing"

	"github.com/ahmedelgabri/dotfiles/config/tmux/scripts/next-prayer/shared"
)

func TestFormatOutput(t *testing.T) {
	t.Run("outside tmux", func(t *testing.T) {
		// t.Setenv registers the restore; formatOutput checks presence via
		// LookupEnv, so the variable must be truly unset, not empty.
		t.Setenv("TMUX", "")
		os.Unsetenv("TMUX")

		got := formatOutput(shared.Output{Item: "Fajr: 04:00", TimeRemaining: 10})
		want := "\033[1;31;40mFajr: 04:00\033[0m"
		if got != want {
			t.Errorf("highlighted output = %q, want %q", got, want)
		}

		got = formatOutput(shared.Output{Item: "Fajr: 04:00", TimeRemaining: 120})
		if got != "Fajr: 04:00" {
			t.Errorf("plain output = %q, want %q", got, "Fajr: 04:00")
		}

		got = formatOutput(shared.Output{Item: "Fajr: 04:00", TimeRemaining: -1})
		if got != "Fajr: 04:00" {
			t.Errorf("after-Isha output = %q, want %q", got, "Fajr: 04:00")
		}
	})

	t.Run("inside tmux", func(t *testing.T) {
		t.Setenv("TMUX", "/tmp/tmux-501/default,1234,0")

		got := formatOutput(shared.Output{Item: "Fajr: 04:00", TimeRemaining: 30})
		want := "#[fg=red]Fajr: 04:00#[default]"
		if got != want {
			t.Errorf("highlighted output = %q, want %q", got, want)
		}
	})
}
