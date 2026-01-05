# Nix daemon configuration - daemon settings, GC, optimization
# Common Nix configuration for all systems
{inputs, ...}:
let
  nixDaemonModule = {
    self,
    config,
    pkgs,
    ...
  }: {
    system.configurationRevision = self.rev or self.dirtyRev or null;

    nix = {
      # @NOTE: for `nix-darwin` this will enable `services.nix-daemon.enable` and `nix.configureBuildUsers'
      enable = true;
      # Disable channels since we are using flakes
      channel.enable = false;
      nixPath.nixpkgs = "${pkgs.path}";
      package = pkgs.nix;
      settings = {
        trusted-users = ["@admin"];
        experimental-features = ["nix-command" "flakes"];
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
        keep-derivations = true;
        keep-outputs = true;
      };
      gc = {
        automatic = true;
        options = "--delete-older-than 3d";
      };
      optimise.automatic = pkgs.stdenv.isDarwin;
    };

    nixpkgs.config.allowUnfree = true;
    time.timeZone = config.my.timezone;

    documentation.man = {
      enable = true;
      # Currently doesn't work in nix-darwin
      # https://discourse.nixos.org/t/man-k-apropos-return-nothing-appropriate/15464
      # generateCaches = true;
    };
  };
in {
  flake.modules.darwin.nix-daemon = {...}: {
    imports = [nixDaemonModule];
    _module.args.self = inputs.self;
  };

  flake.modules.nixos.nix-daemon = {...}: {
    imports = [nixDaemonModule];
    _module.args.self = inputs.self;
  };
}
