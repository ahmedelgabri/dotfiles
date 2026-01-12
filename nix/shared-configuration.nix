# Shared configuration module
# This provides the common configuration for both Darwin and NixOS systems
# Previously this was the sharedConfiguration function in flake.nix
{inputs, ...}: {
  # This module provides shared configuration to darwin and nixos modules
  flake.sharedModules.core = {
    config,
    pkgs,
    lib,
    ...
  }: {
    system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

    nix = {
      # @NOTE: for `nix-darwin` this will enable these old options `services.nix-daemon.enable` and `nix.configureBuildUsers'
      enable = true;
      # Disable channels since we are using flakes
      channel.enable = false;
      nixPath = {
        inherit (inputs) nixpkgs;
        inherit (inputs) darwin;
        inherit (inputs) home-manager;
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

    fonts = {
      packages = with pkgs;
        [pragmatapro]
        ++ (lib.optionals
          pkgs.stdenv.isLinux [
            noto-fonts
            noto-fonts-cjk-sans
            noto-fonts-emoji
            # liberation_ttf
            fira-code
            fira-code-symbols
            mplus-outline-fonts.githubRelease
            dina-font
            proggyfonts
            nerd-fonts.fira-code
            nerd-fonts.droid-sans-mono
          ]);
    };

    nixpkgs = {
      config = {allowUnfree = true;};
      overlays = [
        inputs.yazi.overlays.default
        inputs.nur.overlays.default
        (final: prev: {
          pragmatapro = prev.callPackage ./pkgs/pragmatapro.nix {};
          hcron = prev.callPackage ./pkgs/hcron.nix {};

          next-prayer =
            prev.callPackage
            ../config/tmux/scripts/next-prayer/next-prayer.nix
            {};

          notmuch = prev.notmuch.override {
            withEmacs = false;
          };

          # Nixpkgs is outdated
          zsh-history-substring-search = prev.zsh-history-substring-search.overrideAttrs (oldAttrs: rec {
            version = "master";
            src = prev.fetchFromGitHub {
              owner = "zsh-users";
              repo = oldAttrs.pname;
              rev = version;
              sha256 = "sha256-1+w0AeVJtu1EK5iNVwk3loenFuIyVlQmlw8TWliHZGI=";
            };
          });

          # Nixpkgs is outdated
          zsh-completions = prev.zsh-completions.overrideAttrs (oldAttrs: rec {
            version = "master";
            src = prev.fetchFromGitHub {
              owner = "zsh-users";
              repo = oldAttrs.pname;
              rev = version;
              sha256 = "sha256-C8ebCnNPaSPUEDVxIGIWjdOfr/MmxoBwOB/3pNCkzPc=";
            };
          });

          inherit (inputs.gh-gfm-preview.packages.${prev.stdenv.hostPlatform.system}) gh-gfm-preview;
          inherit (inputs.emmylua-analyzer-rust.packages.${prev.stdenv.hostPlatform.system}) emmylua_ls emmylua_check;
        })
      ];
    };

    time.timeZone = config.my.timezone;

    documentation.man = {
      enable = true;
      # Currently doesn't work in nix-darwin
      # https://discourse.nixos.org/t/man-k-apropos-return-nothing-appropriate/15464
      # generateCaches = true;
    };

    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog

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
}
