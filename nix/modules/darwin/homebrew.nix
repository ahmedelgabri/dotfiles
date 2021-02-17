{ pkgs, lib, config, ... }:

with config.settings;

# [todo] (automate) Requires homebrew to be installed
{
  homebrew.enable = true;
  homebrew.autoUpdate = true;
  homebrew.cleanup = "zap";
  homebrew.global.brewfile = true;
  homebrew.global.noLock = true;

  homebrew.taps = [ "homebrew/cask" ];

  homebrew.brews = [ "mas" ];

  homebrew.casks = [
    "alfred"
    "appcleaner"
    "corelocationcli"
    "db-browser-for-sqlite"
    "figma"
    "brave-browser"
    "google-chrome"
    "hammerspoon"
    "imageoptim"
    "kap"
    "launchcontrol"
    "obsidian"
    "slack"
    "sync"
    "virtualbox"
    "homebrew/cask-versions/visual-studio-code-insiders"
    # "vscodium"
    "zoom"
  ];

  # Requires to be logged in to the AppStore
  # Cleanup doesn't work automatically if you add/remove to list
  homebrew.masApps = { "1Password 7" = 1333542190; };

  home-manager = {
    users.${username} = {
      home = {
        file = {
          ".hammerspoon" = {
            recursive = true;
            source = ../../../config/.hammerspoon;
          };
        };
      };
    };
  };
}
