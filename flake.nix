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

{
  description = "~ 🍭 ~";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    n = {
      url = "github:tj/n";
      flake = false;
    };

    ttrv = {
      url = "github:tildeclub/ttrv?ref=v1.27.3";
      flake = false;
    };

    weechat-scripts = {
      url = "github:weechat/scripts";
      flake = false;
    };

    rnix-lsp = {
      url = "github:nix-community/rnix-lsp";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zk = {
      url = "github:mickael-menu/zk";
      flake = false;
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Extras
    # nixos-hardware.url = "github:nixos/nixos-hardware";
  };

  outputs = { self, ... }@inputs:
    let
      sharedHostsConfig = { config, pkgs, lib, options, ... }: {
        nix = {
          nixPath = [
            "nixpkgs=${inputs.nixpkgs}"
            "darwin=${inputs.darwin}"
            "home-manager=${inputs.home-manager}"
          ];
          package = pkgs.nixFlakes;
          extraOptions = "experimental-features = nix-command flakes";
          binaryCaches = [
            "https://cache.nixos.org"
            "https://nix-community.cachix.org"
            "https://nixpkgs.cachix.org"
            "https://srid.cachix.org"
            "https://nix-linter.cachix.org"
            "https://statix.cachix.org"
          ];
          binaryCachePublicKeys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE="
            "srid.cachix.org-1:MTQ6ksbfz3LBMmjyPh0PLmos+1x+CdtJxA/J2W+PQxI="
            "nix-linter.cachix.org-1:BdTne5LEHQfIoJh4RsoVdgvqfObpyHO5L0SCjXFShlE="
            "statix.cachix.org-1:Z9E/g1YjCjU117QOOt07OjhljCoRZddiAm4VVESvais="
          ];
          gc = {
            automatic = true;
            options = "--delete-older-than 3d";
          };
        };

        fonts = {
          enableFontDir = true;
          # fontDir.enable = true;
          fonts = with pkgs; [ pragmatapro ];
        };

        nixpkgs = {
          config = { allowUnfree = true; };
          overlays = [ self.overlay inputs.rust-overlay.overlay ];
        };

        time.timeZone = config.my.timezone;

        documentation.man = {
          enable = true;
          # Currently doesn't work in nix-darwin
          # https://discourse.nixos.org/t/man-k-apropos-return-nothing-appropriate/15464
          # generateCaches = true;
        };

      };

    in
    {
      overlay = (final: prev: {
        pragmatapro = (prev.callPackage ./nix/pkgs/pragmatapro.nix { });

        zk = (prev.callPackage ./nix/pkgs/zk.nix { source = inputs.zk; });

        pure-prompt = prev.pure-prompt.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ./nix/hosts/pure-zsh.patch ];
        });
      });

      darwinConfigurations = {
        "pandoras-box" = inputs.darwin.lib.darwinSystem {
          system = "x86_64-darwin";
          inputs = inputs;
          modules = [
            inputs.home-manager.darwinModules.home-manager
            ./nix/modules/shared
            sharedHostsConfig
            ./nix/hosts/pandoras-box.nix
          ];
        };

        "ahmed-at-work" = inputs.darwin.lib.darwinSystem {
          system = "x86_64-darwin";
          inputs = inputs;
          modules = [
            inputs.home-manager.darwinModules.home-manager
            ./nix/modules/shared
            sharedHostsConfig
            ./nix/hosts/ahmed-at-work.nix
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
    };
}
