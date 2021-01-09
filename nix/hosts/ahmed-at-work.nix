{ config, pkgs, lib, inputs, ... }: {
  settings = {
    username = "ahmedelgabri";
    email = "ahmed@miro.com";
  };

  networking = { hostName = "ahmed-at-work"; };

  nix = {
    gc = { user = config.settings.username; };
    # Auto upgrade nix package and the daemon service.
    # services.nix-daemon.enable = true;
    # nix.package = pkgs.nix;
    # nix.maxJobs = 4;
    # nix.buildCores = 4;
  };

  imports = [ ../modules/darwin ];

  my = {
    macos.enable = true;
    hammerspoon.enable = true;
    apps.enable = true;
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

  users.users.${config.settings.username} = {
    home = "/Users/${config.settings.username}";
  };

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
