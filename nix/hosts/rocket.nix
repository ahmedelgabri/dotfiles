{ config, pkgs, lib, inputs, ... }: {
  imports = [ ../modules/darwin ];

  my = {
    username = "ahmedelgabri";
    email = "ahmed@miro.com";
    website = "https://miro.com";
    modules = {
      macos.enable = true;
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
  };

  networking = { hostName = "rocket"; };
  nix = {
    gc = { user = config.my.username; };
  };

  my.user = {
    packages = with pkgs; [
      # emacsMacport
      go-task
      localstack
      glow
      graph-easy
      graphviz
      nodePackages.mermaid-cli
      emanote
      # go-jira
      jira-cli-go
    ];
  };

  homebrew.casks = [
    "temurin8" # -> adoptopenjdk8
    "corretto"
    "firefox"
    "loom"
    "vagrant"
    "discord"
    "docker"
    "ngrok"
    "figma"
  ];

  homebrew.brews = [
    "amp"
    "git"
    "git-filter-repo"
    "git-lfs"
    "git-sizer"
    "awscli"
    "k9s"
    "aws-vault"
  ];

  # Requires to be logged in to the AppStore
  # Cleanup doesn't work automatically if you add/remove to list
  # homebrew.masApps = {
  #   Twitter = 1482454543;
  #   Sip = 507257563;
  #   Guidance = 412759995;
  # };

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";
}
