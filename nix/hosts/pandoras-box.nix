{ config, pkgs, lib, inputs, ... }: {
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

    mail = { enable = true; };
    aerc = { enable = true; };
    youtube-dl.enable = true;
    irc.enable = true;
    rescript.enable = true;
    clojure.enable = true;
    newsboat.enable = true;
    gpg.enable = true;
  };

  environment.systemPackages = with pkgs; [
    (pkgs.callPackage ../pkgs/arq.nix { })
    (pkgs.callPackage ../pkgs/signal.nix { })
  ];

  networking = { hostName = "pandoras-box"; };

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
