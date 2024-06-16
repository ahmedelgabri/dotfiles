package main

import (
	"flag"
	"fmt"
	"os"

	"github.com/ahmedelgabri/dotfiles/config/tmux/scripts/next-prayer/aladhan"
	"github.com/ahmedelgabri/dotfiles/config/tmux/scripts/next-prayer/mawaqit"
	"github.com/ahmedelgabri/dotfiles/config/tmux/scripts/next-prayer/shared"
)

var (
	version string
)

func formatOutput(output shared.Output) string {
	red := "\033[1;31;40m"

	if _, isTmux := os.LookupEnv("TMUX"); isTmux {
		red = "#[fg=red]"
	}

	if output.TimeRemaining > -1 && output.TimeRemaining <= 30 {
		return red + output.Item
	}

	return output.Item
}

func print_help() {
	fmt.Printf(`
Usage
 $ next-prayer [command] [options]

Commands
    mawaqit     Get prayers times from Mawaqit
    aladhan     Get prayers times from Aladhan

Options
    --version   Print the CLI version (%s)
    --help      Print this help
`, version)
}

func main() {
	mawaqitCmd := flag.NewFlagSet("mawaqit", flag.ExitOnError)
	aladhanCmd := flag.NewFlagSet("aladhan", flag.ExitOnError)

	if len(os.Args) < 2 {
		print_help()
		os.Exit(1)
	}

	switch os.Args[1] {
	case "mawaqit":
		username := mawaqitCmd.String("username", os.Getenv("MAWAQIT_USERNAME"), "Mawaqit Username")
		password := mawaqitCmd.String("password", os.Getenv("MAWAQIT_PASSWORD"), "Mawaqit Password")
		latitude := mawaqitCmd.String("latitude", os.Getenv("MAWAQIT_LATITUDE"), "Latitude")
		longitude := mawaqitCmd.String("longitude", os.Getenv("MAWAQIT_LONGITUDE"), "Longitude")
		help := mawaqitCmd.Bool("help", false, "Help!")

		mawaqitCmd.Parse(os.Args[2:])

		s := mawaqit.New(mawaqit.Flags{
			Username:  username,
			Password:  password,
			Latitude:  latitude,
			Longitude: longitude,
		})

		if *help {
			s.PrintHelp()
			return
		}

		result := shared.Get_prayer(s)

		fmt.Println(formatOutput(result))
		return
	case "aladhan":
		// https://aladhan.com/prayer-times-api#GetCalendarByCitys
		city := aladhanCmd.String("city", "Almere", "City name")
		country := aladhanCmd.String("country", "nl", "Country name")
		method := aladhanCmd.Int("method", 12, "Prayer method")
		tune := aladhanCmd.String("tune", "0,-18,0,0,0,0,0,12,0", "Prayer time tuning")
		help := aladhanCmd.Bool("help", false, "Help!")

		aladhanCmd.Parse(os.Args[2:])

		s := aladhan.New(aladhan.Flags{
			Country: country,
			City:    city,
			Method:  method,
			Tune:    tune,
		})

		if *help {
			s.PrintHelp()
			return
		}

		result := shared.Get_prayer(s)

		fmt.Println(formatOutput(result))
		return
	default:
		version := flag.Bool("version", false, "CLI version")
		help := flag.Bool("help", false, "Help!")

		flag.Parse()

		if *help {
			print_help()
			return
		}

		if *version {
			fmt.Println(version)
			return
		}

		fmt.Println("expected 'mawaqit' or 'aladhan' subcommands")
		os.Exit(1)
	}
}
