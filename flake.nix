# As a first step, I will try to symlink my configs as much as possible then
# migrate the configs to Nix
#
# https://nixcloud.io/ for Nix syntax
# https://nix.dev/
# https://nixos.org/guides/nix-pills/
# https://nix-community.github.io/awesome-nix/
# https://discourse.nixos.org/t/home-manager-equivalent-of-apt-upgrade/8424/3
# https://www.reddit.com/r/NixOS/comments/jmom4h/new_neofetch_nixos_logo/gayfal2/
# https://www.youtube.com/user/elitespartan117j27/videos?view=0&sort=da&flow=grid
# https://www.youtube.com/playlist?list=PLRGI9KQ3_HP_OFRG6R-p4iFgMSK1t5BHs
# https://www.reddit.com/r/NixOS/comments/k9xwht/best_resources_for_learning_nixos/
# https://www.reddit.com/r/NixOS/comments/k8zobm/nixos_preferred_packages_flow/
# https://www.reddit.com/r/NixOS/comments/j4k2zz/does_anyone_use_flakes_to_manage_their_entire/
# https://serokell.io/blog/practical-nix-flakes
# https://stephank.nl/p/2023-02-28-using-flakes-for-nixos-configs.html
# https://zero-to-nix.com/

{
  description = "~ 🍭 ~";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    weechat-scripts = {
      url = "github:weechat/scripts";
      flake = false;
    };

    neovim = {
      url = "github:neovim/neovim?dir=contrib&ref=v0.9.5";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    # Extras
    # nixos-hardware.url = "github:nixos/nixos-hardware";
  };

  outputs = { self, flake-utils, ... }@inputs:
    let
      sharedHostsConfig = { config, pkgs, ... }: {
        # enable sudo authentication with Touch ID
        security.pam.enableSudoTouchIdAuth = pkgs.stdenv.isDarwin;
        nix = {
          useDaemon = true;
          nixPath = [
            "nixpkgs=${inputs.nixpkgs}"
            "darwin=${inputs.darwin}"
            "home-manager=${inputs.home-manager}"
          ];
          package = pkgs.nixVersions.unstable;
          extraOptions = "experimental-features = nix-command flakes";
          settings = {
            substituters = [
              "https://cache.nixos.org"
              "https://nix-community.cachix.org"
              "https://nixpkgs.cachix.org"
              "https://srid.cachix.org"
              "https://nix-linter.cachix.org"
              "https://statix.cachix.org"
            ];
            trusted-public-keys = [
              "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              "nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE="
              "srid.cachix.org-1:MTQ6ksbfz3LBMmjyPh0PLmos+1x+CdtJxA/J2W+PQxI="
              "nix-linter.cachix.org-1:BdTne5LEHQfIoJh4RsoVdgvqfObpyHO5L0SCjXFShlE="
              "statix.cachix.org-1:Z9E/g1YjCjU117QOOt07OjhljCoRZddiAm4VVESvais="
            ];
          };
          gc = {
            automatic = true;
            options = "--delete-older-than 3d";
          };
        };

        fonts = {
          fontDir.enable = true;
          fonts = with pkgs; [ pragmatapro ] ++ (lib.optionals
            pkgs.stdenv.isLinux [
            noto-fonts
            noto-fonts-cjk
            noto-fonts-emoji
            # liberation_ttf
            fira-code
            fira-code-symbols
            mplus-outline-fonts
            dina-font
            proggyfonts
            (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
          ]);
        };

        nixpkgs = {
          config = { allowUnfree = true; };
          overlays = [
            self.overlay
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
        # on your system were taken. It‘s perfectly fine and recommended to leave
        # this value at the release version of the first install of this system.
        # Before changing this value read the documentation for this option
        # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
        # https://nixos.org/manual/nixos/stable/index.html#sec-upgrading
        system.stateVersion = if pkgs.stdenv.isDarwin then 4 else "20.09"; # Did you read the comment?
      };
    in
    {
      overlay = _: prev: {
        pragmatapro = prev.callPackage ./nix/pkgs/pragmatapro.nix { };
        hcron = prev.callPackage ./nix/pkgs/hcron.nix { };

        next-prayer = prev.callPackage
          ./config/tmux/scripts/next-prayer/next-prayer.nix
          { };

        pure-prompt = prev.pure-prompt.overrideAttrs (old: {
          patches = (old.patches or[ ]) ++ [ ./nix/hosts/pure-zsh.patch ];
        });

        neovim-git = inputs.neovim.defaultPackage.${ prev.system};

        notmuch = prev.notmuch.override {
          withEmacs = false;
        };
      };

      darwinConfigurations = {
        "pandoras-box" = inputs.darwin.lib.darwinSystem {
          system = "x86_64-darwin";
          inherit inputs;
          modules = [
            inputs.home-manager.darwinModules.home-manager
            ./nix/modules/shared
            sharedHostsConfig
            ./nix/hosts/pandoras-box.nix
          ];
        };

        "rocket" = inputs.darwin.lib.darwinSystem {
          system = "aarch64-darwin";
          inherit inputs;
          modules = [
            inputs.home-manager.darwinModules.home-manager
            ./nix/modules/shared
            sharedHostsConfig
            ./nix/hosts/rocket.nix
          ];
        };
      };

      # for convenience
      # nix build './#darwinConfigurations.pandoras-box.system'
      # vs
      # nix build './#pandoras-box'
      # Move them to `outputs.packages.<system>.name`
      pandoras-box = self.darwinConfigurations.pandoras-box.system;
      ahmed-at-work = self.darwinConfigurations.ahmed-at-work.system;
      rocket = self.darwinConfigurations.rocket.system;

      nixosConfigurations = {
        "nixos" = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            inputs.home-manager.nixosModules.home-manager
            ./nix/modules/shared
            sharedHostsConfig
            ./nix/hosts/nixos
          ];
        };
      };
    } // flake-utils.lib.eachDefaultSystem (system: {
      # @TODO: move the logic inside ./install here
      devShells =
        let
          pkgs = inputs.nixpkgs.legacyPackages.${system};
          homebrewInstall = pkgs.writeShellScriptBin "homebrewInstall" ''${pkgs.bash}/bin/bash -c "$(${pkgs.curl}/bin/curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"'';
        in
        {
          default = pkgs.mkShell {
            name = "dotfiles";
            buildInputs = with pkgs; [
              delve # dlv
              go
              go-tools # staticcheck
              gomodifytags
              gopls
              gotests
              gotools # goimports
              impl
              revive
            ] ++ (lib.optionals pkgs.stdenv.isDarwin [ homebrewInstall ]);
            # shellHook = ''echo "hi"'';
          };
        };

      # default = (pkgs.writeShellScriptBin "foo" ''echo "foo" ''));
    });
}
