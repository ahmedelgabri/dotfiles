{ pkgs, ... }: {
  networking = { hostName = "rocket"; };

  my = {
    username = "ahmedelgabri";
    email = "ahmed@miro.com";
    website = "https://miro.com";
    modules = {
      gpg.enable = true;
      mail = {
        enable = true;
        account = "Work";
        alias_path = "";
        keychain = { name = "gmail.com"; };
        imap_server = "imap.gmail.com";
        smtp_server = "smtp.gmail.com";
      };
    };
    user = {
      packages = with pkgs; [
        # emacsMacport
        go-task
        localstack
        graph-easy
        graphviz
        nodePackages.mermaid-cli
        # emanote
        jira-cli-go
      ];
    };
  };

  homebrew = {
    casks = [
      "temurin8" # -> adoptopenjdk8
      "corretto"
      "firefox"
      "loom"
      "vagrant"
      "docker"
      "ngrok"
      "figma"
      "jordanbaird-ice"
    ];

    brews = [
      "amp"
      "git"
      "git-filter-repo"
      "git-lfs"
      "git-sizer"
      "awscli"
      "k9s"
      "aws-vault"
      "httpstat"
    ];

    # Requires to be logged in to the AppStore
    # Cleanup doesn't work automatically if you add/remove to list
    # masApps = {
    #   Twitter = 1482454543;
    #   Sip = 507257563;
    #   Guidance = 412759995;
    # }
  };
}
