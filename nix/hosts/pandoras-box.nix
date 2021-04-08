{ config, pkgs, lib, inputs, ... }: {
  nix = {
    gc = { user = config.my.username; };
    # Auto upgrade nix package and the daemon service.
    # services.nix-daemon.enable = true;
    # nix.package = pkgs.nix;
    # nix.maxJobs = 4;
    # nix.buildCores = 4;
  };

  imports = [ ../modules/darwin ];

  my = {
    modules = {
      macos.enable = true;

      mail = { enable = true; };
      aerc = { enable = true; };
      youtube-dl.enable = true;
      irc.enable = true;
      rescript.enable = false;
      clojure.enable = true;
      newsboat.enable = true;
    };
  };

  homebrew.casks = [
    # "arq" # I need a specific version so I will handle it myself.
    "transmit"
    "jdownloader"
    "signal"
  ];

  # Requires to be logged in to the AppStore
  # Cleanup doesn't work automatically if you add/remove to list
  homebrew.masApps = {
    Guidance = 412759995;
    NextDNS = 1464122853;
    Dato = 1470584107;
    "Day One" = 1055511498;
    WireGuard = 1451685025;
    Tweetbot = 1384080005;
    Todoist = 585829637;
    Sip = 507257563;
    Irvue = 1039633667;
    Telegram = 747648890;
  };

  networking = { hostName = "pandoras-box"; };

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
