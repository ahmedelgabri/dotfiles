{ config, pkgs, lib, inputs, ... }: {
  imports = [ ../modules/darwin ];

  my = {
    username = "ahmedelgabri";
    email = "ahmed@miro.com";
    website = "https://miro.com";
    modules = {
      macos.enable = true;
      java.enable = false;
      kotlin.enable = true;
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

  networking = { hostName = "ahmed-at-work"; };

  nix = {
    gc = { user = config.my.username; };
    # Auto upgrade nix package and the daemon service.
    # services.nix-daemon.enable = true;
    # nix.package = pkgs.nix;
    # nix.maxJobs = 4;
    # nix.buildCores = 4;
  };

  my.user = {
    packages = with pkgs; [
      emacs
    ];
  };

  homebrew.casks = [
    "adoptopenjdk8"
    "corretto"
    "firefox"
    "loom"
    "vagrant"
    "discord"
  ];

  # Requires to be logged in to the AppStore
  # Cleanup doesn't work automatically if you add/remove to list
  # homebrew.masApps = {
  #   Twitter = 1482454543;
  #   Sip = 507257563;
  #   Xcode = 497799835;
  #   Guidance = 412759995;
  # };

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
