package main

import (
	"flag"
	"fmt"
	"os"

	"github.com/ahmedelgabri/dotfiles/config/tmux/scripts/next-prayer/aladhan"
	"github.com/ahmedelgabri/dotfiles/config/tmux/scripts/next-prayer/config"
	"github.com/ahmedelgabri/dotfiles/config/tmux/scripts/next-prayer/mawaqit"
	"github.com/ahmedelgabri/dotfiles/config/tmux/scripts/next-prayer/shared"
)

var version string

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

func printHelp() {
	fmt.Printf(`
Usage
    $ next-prayer <command> [options]

Commands
    mawaqit     Get prayer times from Mawaqit
    aladhan     Get prayer times from Aladhan

Options
    --version   Print the CLI version (%s)
    --help      Print this help

Configuration
    Config file: $XDG_CONFIG_HOME/prayer-times/config.toml

    Resolution order: CLI flag > config file > environment variable
`, version)
}

func fatal(format string, args ...any) {
	fmt.Fprintf(os.Stderr, "error: "+format+"\n", args...)
	os.Exit(1)
}

func main() {
	if len(os.Args) < 2 {
		printHelp()
		os.Exit(1)
	}

	switch os.Args[1] {
	case "mawaqit":
		runMawaqit()
	case "aladhan":
		runAladhan()
	default:
		showVersion := flag.Bool("version", false, "CLI version")
		help := flag.Bool("help", false, "Help!")
		flag.Parse()

		if *help {
			printHelp()
			return
		}
		if *showVersion {
			fmt.Println(version)
			return
		}

		fmt.Fprintf(os.Stderr, "unknown command: %s\n", os.Args[1])
		printHelp()
		os.Exit(1)
	}
}

func runMawaqit() {
	fs := flag.NewFlagSet("mawaqit", flag.ExitOnError)

	configPath := fs.String("config", "", "Config file path override")
	username := fs.String("username", "", "Mawaqit username")
	password := fs.String("password", "", "Mawaqit password")
	latitude := fs.Float64("latitude", 0, "Latitude")
	longitude := fs.Float64("longitude", 0, "Longitude")
	city := fs.String("city", "", "City (for cache keying)")
	country := fs.String("country", "", "Country (for cache keying)")
	mosque := fs.String("mosque", "", "Mosque name, label, slug, associationName, or UUID")
	listMosques := fs.Bool("list-mosques", false, "List nearby mosques and exit")
	help := fs.Bool("help", false, "Print help")

	fs.Parse(os.Args[2:])

	if *help {
		mawaqit.PrintHelp()
		return
	}

	cfg, err := config.Load(*configPath)
	if err != nil {
		fatal("%s", err)
	}

	params := mawaqit.Params{
		Username:  config.ResolveString(*username, cfg.Mawaqit.Username, "MAWAQIT_USERNAME"),
		Password:  config.ResolveString(*password, cfg.Mawaqit.Password, "MAWAQIT_PASSWORD"),
		Latitude:  config.ResolveFloat64(*latitude, cfg.Mawaqit.Latitude, "MAWAQIT_LATITUDE"),
		Longitude: config.ResolveFloat64(*longitude, cfg.Mawaqit.Longitude, "MAWAQIT_LONGITUDE"),
		Mosque:    config.ResolveString(*mosque, cfg.Mawaqit.Mosque, ""),
	}

	if *listMosques {
		if err := mawaqit.ListMosques(params); err != nil {
			fatal("%s", err)
		}
		return
	}

	loc := shared.CacheLocation{
		City:    config.ResolveString(*city, "", ""),
		Country: config.ResolveString(*country, "", ""),
	}

	s := mawaqit.New(params)
	result, err := shared.GetPrayer(s, loc)
	if err != nil {
		fatal("%s", err)
	}

	fmt.Println(formatOutput(result))
}

func runAladhan() {
	fs := flag.NewFlagSet("aladhan", flag.ExitOnError)

	configPath := fs.String("config", "", "Config file path override")
	city := fs.String("city", "", "City name")
	country := fs.String("country", "", "Country name or code")
	method := fs.Int("method", 0, "Calculation method")
	tune := fs.String("tune", "", "Prayer time tuning")
	help := fs.Bool("help", false, "Print help")

	fs.Parse(os.Args[2:])

	if *help {
		aladhan.PrintHelp()
		return
	}

	cfg, err := config.Load(*configPath)
	if err != nil {
		fatal("%s", err)
	}

	resolvedCity := config.ResolveString(*city, cfg.Aladhan.City, "ALADHAN_CITY")
	resolvedCountry := config.ResolveString(*country, cfg.Aladhan.Country, "ALADHAN_COUNTRY")

	params := aladhan.Params{
		City:    resolvedCity,
		Country: resolvedCountry,
		Method:  config.ResolveInt(*method, cfg.Aladhan.Method, "ALADHAN_METHOD"),
		Tune:    config.ResolveString(*tune, cfg.Aladhan.Tune, "ALADHAN_TUNE"),
	}

	loc := shared.CacheLocation{
		City:    resolvedCity,
		Country: resolvedCountry,
	}

	s := aladhan.New(params)
	result, err := shared.GetPrayer(s, loc)
	if err != nil {
		fatal("%s", err)
	}

	fmt.Println(formatOutput(result))
}
