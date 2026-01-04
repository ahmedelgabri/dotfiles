# Nix daemon configuration - works on both Darwin and NixOS
# Configures nix settings, garbage collection, and system state
{inputs, ...}:
let
  # Shared nix configuration for both platforms
  nixModule = {
    self,
    config,
    pkgs,
    ...
  }: {
    system.configurationRevision = self.rev or self.dirtyRev or null;

    nix = {
      # @NOTE: for `nix-darwin` this will enable these old options `services.nix-daemon.enable` and `nix.configureBuildUsers'
      enable = true;
      # Disable channels since we are using flakes
      channel.enable = false;
      nixPath = {
        nixpkgs = "${pkgs.path}";
      };
      package = pkgs.nix;
      settings = {
        trusted-users = ["@admin"];
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        # disabled on Darwin because some buggy behaviour: https://github.com/NixOS/nix/issues/7273
        auto-optimise-store = !pkgs.stdenv.isDarwin;
        substituters = [
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
          "https://nixpkgs.cachix.org"
          "https://yazi.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          "nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE="
          "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
        ];
        # Recommended when using `direnv` etc.
        keep-derivations = true;
        keep-outputs = true;
      };
      gc = {
        automatic = true;
        options = "--delete-older-than 3d";
      };
      optimise = {
        # Enable store optimization because we can't set `auto-optimise-store` to true on macOS.
        automatic = pkgs.stdenv.isDarwin;
      };
    };

    nixpkgs.config.allowUnfree = true;

    time.timeZone = config.my.timezone;

    documentation.man = {
      enable = true;
      # Currently doesn't work in nix-darwin
      # https://discourse.nixos.org/t/man-k-apropos-return-nothing-appropriate/15464
      # generateCaches = true;
    };

    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    #
    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It's perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    # https://nixos.org/manual/nixos/stable/index.html#sec-upgrading
    system.stateVersion =
      if pkgs.stdenv.isDarwin
      then 5
      else "24.05"; # Did you read the comment?

    home-manager.users."${config.my.username}" = {
      home = {
        # Necessary for home-manager to work with flakes, otherwise it will
        # look for a nixpkgs channel.
        stateVersion =
          if pkgs.stdenv.isDarwin
          then "24.05"
          else config.system.stateVersion;
      };
    };
  };
in {
  # Define the module for both darwin and nixos
  flake.modules.darwin.nix = {...}: {
    imports = [nixModule];
    # Darwin receives self through top-level specialArgs
    _module.args.self = inputs.self;
  };

  flake.modules.nixos.nix = {...}: {
    imports = [nixModule];
    # NixOS receives self through top-level specialArgs
    _module.args.self = inputs.self;
  };
}
