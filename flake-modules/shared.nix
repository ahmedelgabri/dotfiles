{
  inputs,
  self,
  ...
}: {
  flake.modules.generic.core = {
    pkgs,
    config,
    ...
  }: {
    system.configurationRevision = self.rev or self.dirtyRev or null;

    nix = {
      # @NOTE: for `nix-darwin` this will enable these old options `services.nix-daemon.enable` and `nix.configureBuildUsers'
      enable = true;
      # Disable channels since we are using flakes
      channel.enable = false;
      package = pkgs.nix;
      settings = {
        trusted-users = ["@admin"];
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        # Recommended when using `direnv` etc.
        keep-derivations = true;
        keep-outputs = true;
      };
      gc = {
        automatic = true;
        options = "--delete-older-than 3d";
      };
    };

    time.timeZone = config.my.timezone;

    documentation.man = {
      enable = true;
      # Currently doesn't work in nix-darwin
      # https://discourse.nixos.org/t/man-k-apropos-return-nothing-appropriate/15464
      # generateCaches = true;
    };

    fonts = {
      packages = with pkgs; [pragmatapro];
    };
  };

  flake.modules.nixos.core = {
    pkgs,
    config,
    ...
  }: {
    nix = {
      nixPath = {
        inherit (inputs) nixpkgs;
        inherit (inputs) home-manager;
      };
      package = pkgs.nix;
      settings = {
        auto-optimise-store = true;
      };
    };

    fonts = {
      packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk
        noto-fonts-emoji
        # liberation_ttf
        fira-code
        fira-code-symbols
        mplus-outline-fonts
        dina-font
        proggyfonts
        (nerdfonts.override {fonts = ["FiraCode" "DroidSansMono"];})
      ];
    };

    documentation.man = {
      generateCaches = true;
    };

    # This value determines the NixOS release from which the default
    # settings for stateful data, like file locations and database versions
    # on your system were taken. It's perfectly fine and recommended to leave
    # this value at the release version of the first install of this system.
    # Before changing this value read the documentation for this option
    # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
    # https://nixos.org/manual/nixos/stable/index.html#sec-upgrading
    system.stateVersion = "24.05"; # Did you read the comment?

    home-manager.users."${config.my.username}" = {
      home = {
        # Necessary for home-manager to work with flakes, otherwise it will
        # look for a nixpkgs channel.
        inherit (config.system) stateVersion;
      };
    };
  };

  flake.modules.darwin.core = {
    pkgs,
    config,
    ...
  }: {
    nix = {
      nixPath = {
        inherit (inputs) nixpkgs;
        inherit (inputs) darwin;
        inherit (inputs) home-manager;
      };
      settings = {
        # disabled on Darwin because some buggy behaviour: https://github.com/NixOS/nix/issues/7273
        auto-optimise-store = false;
      };
      optimise = {
        # Enable store optimization because we can't set `auto-optimise-store` to true on macOS.
        automatic = pkgs.stdenv.isDarwin;
      };
    };

    # Used for backwards compatibility, please read the changelog before changing.
    # $ darwin-rebuild changelog
    system.stateVersion = 5;

    home-manager.users."${config.my.username}" = {
      home = {
        # Necessary for home-manager to work with flakes, otherwise it will
        # look for a nixpkgs channel.
        stateVersion = "24.05";
      };
    };
  };
}
