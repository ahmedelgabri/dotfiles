let
  module = {
    darwin = _: {
      config = {
        homebrew.casks = [
          "1password"
          "raycast"
          "anki"
          "appcleaner"
          "firefox"
          "imageoptim"
          "kap"
          "launchcontrol"
          "notion-calendar"
          "obsidian"
          "slack"
          "sync"
          "zoom"
          "telegram"
          "handy"
        ];
      };
    };

    nixos =
      { pkgs, ... }:
      {
        config = {
          my.user.packages = with pkgs; [
            docker
            firefox
            brave
            obsidian
            signal-desktop
            slack
            zoom-us
          ];
        };
      };
  };
in
{
  flake = {
    modules = {
      darwin.gui = module.darwin;
      nixos.gui = module.nixos;
    };
  };
}
