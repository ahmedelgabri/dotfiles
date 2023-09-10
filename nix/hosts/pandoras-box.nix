{ config, ... }: {
  imports = [ ../modules/darwin ];

  nix = {
    gc = { user = config.my.username; };
    # Auto upgrade nix package and the daemon service.
    # services.nix-daemon.enable = true;
    # nix.package = pkgs.nix;
    # nix.maxJobs = 4;
    # nix.buildCores = 4;
  };

  my = {
    modules = {
      macos.enable = true;

      mail = { enable = true; };
      irc.enable = true;
      gpg.enable = true;
      discord.enable = true;
      hledger.enable = true;
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
  # homebrew.masApps = {
  #   Guidance = 412759995;
  #   Dato = 1470584107;
  #   "Day One" = 1055511498;
  #   Tweetbot = 1384080005;
  #   Todoist = 585829637;
  #   Sip = 507257563;
  #   Irvue = 1039633667;
  #   Telegram = 747648890;
  # };

  networking = { hostName = "pandoras-box"; };

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
