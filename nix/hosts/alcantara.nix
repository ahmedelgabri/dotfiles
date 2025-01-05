_: {
  networking = {hostName = "alcantara";};

  my = {
    modules = {
      mail = {enable = true;};
      irc.enable = true;
      gpg.enable = true;
      discord.enable = true;
      hledger.enable = true;
    };
  };

  homebrew = {
    casks = [
      # "arq" # I need a specific version so I will handle it myself.
      "transmit"
      "jdownloader"
      "brave-browser"
      "signal"
      "monodraw"
      "cursor"
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
