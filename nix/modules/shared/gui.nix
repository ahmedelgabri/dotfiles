{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.gui;

in {
  options = with lib; {
    my.gui = {
      enable = mkEnableOption ''
        Whether to enable gui module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable (mkMerge [
      # [todo] (automate) Requires homebrew to be installed
      (mkIf pkgs.stdenv.isDarwin {
        homebrew.taps = [ "homebrew/cask" "homebrew/cask-versions" ];
        homebrew.brews = [ "mas" ];
        homebrew.casks = [
          "1password"
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
      })

      (mkIf pkgs.stdenv.isLinux {
        users.users.${username} = {
          packages = with pkgs; [
            brave
            firefox
            obsidian
            zoom-us
            signal-desktop
            vscodium
            slack
            # sqlitebrowser
            # virtualbox
          ];
        };
      })
    ]);
}
