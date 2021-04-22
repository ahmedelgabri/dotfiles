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
        # [todo] (automate) Requires homebrew to be installed
        homebrew.taps = [ "homebrew/cask" "homebrew/cask-versions" ];
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

        my.hm.file = {
          ".hammerspoon" = {
            recursive = true;
            source = ../../../config/.hammerspoon;
          };
        };
      } else {
        my.user = {
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
