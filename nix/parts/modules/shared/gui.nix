let
  module = {
    darwin = _: {
      config = {
        homebrew.casks = [
          "1password"
          "raycast"
          "appcleaner"
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
          # Also installs the docker CLI; without the daemon the bare
          # package was a client with nothing to talk to.
          virtualisation.docker.enable = true;

          my.user.packages = with pkgs; [
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
