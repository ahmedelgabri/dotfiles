{ config, ... }: {
  imports = [ ../modules/darwin ];

  networking = { hostName = "pandoras-box"; };

  nix = {
    gc = { user = config.my.username; };
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

  nix-homebrew = {
    enable = true;
    enableRosetta = false;
    user = config.my.username;
    autoMigrate = true;
  };

  homebrew = {
    casks = [
      # "arq" # I need a specific version so I will handle it myself.
      "transmit"
      "jdownloader"
      "signal"
    ];

    # Requires to be logged in to the AppStore
    # Cleanup doesn't work automatically if you add/remove to list
    # masApps = {
    #   Guidance = 412759995;
    #   Dato = 1470584107;
    #   "Day One" = 1055511498;
    #   Tweetbot = 1384080005;
    #   Todoist = 585829637;
    #   Sip = 507257563;
    #   Irvue = 1039633667;
    #   Telegram = 747648890;
    # };
  };

}
