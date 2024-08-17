{ pkgs, lib, config, options, ... }:

let

  cfg = config.my.modules.gui;

in
{
  options = with lib; {
    my.modules.gui = {
      enable = mkEnableOption ''
        Whether to enable gui module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable (mkMerge [
      (if (builtins.hasAttr "homebrew" options) then {
        # TODO: (automate) Requires homebrew to be installed
        homebrew.taps = [ "homebrew/cask-versions" ];
        homebrew.casks = [
          "1password"
          "raycast"
          "anki"
          "arc"
          "appcleaner"
          "corelocationcli"
          "brave-browser"
          "firefox"
          # "google-chrome"
          "orion"
          "hammerspoon"
          "imageoptim"
          "kap"
          "launchcontrol"
          "obsidian"
          "slack"
          "sync"
          "visual-studio-code"
          "zoom"
        ];

        my.hm.file = {
          ".hammerspoon" = {
            recursive = true;
            source = ../../../config/.hammerspoon;
          };
        };
      } else {
        my.user = {
          packages = with pkgs; [
            anki
            brave
            firefox
            obsidian
            zoom-us
            signal-desktop
            vscodium
            slack
            docker
            # sqlitebrowser
            # virtualbox
          ];
        };
      })
    ]);
}
