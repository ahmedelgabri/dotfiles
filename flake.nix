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

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
      inputs = {
        nix-darwin.follows = "darwin";
        flake-utils.follows = "flake-utils";
        nixpkgs.follows = "nixpkgs";
      };
    };

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };


    # https://github.com/NixOS/nixpkgs/issues/327836#issuecomment-2292084100
    darwin-nixpkgs.url = "github:nixos/nixpkgs?rev=2e92235aa591abc613504fde2546d6f78b18c0cd";


    weechat-scripts = {
      url = "github:weechat/scripts";
      flake = false;
    };

    nur = {
      url = "github:nix-community/nur";
    };

    # Extras
    # nixos-hardware.url = "github:nixos/nixos-hardware";
  };

  outputs = { self, flake-utils, ... }@inputs:
    let
      darwinHosts = {
        "pandoras-box" = "x86_64-darwin";
        "rocket" = "aarch64-darwin";
      };

      darwinSystems = inputs.nixpkgs.lib.unique (inputs.nixpkgs.lib.attrValues darwinHosts);

      linuxHosts = {
        "nixos" = "x86_64-linux";
      };

      linuxSystems = inputs.nixpkgs.lib.unique (inputs.nixpkgs.lib.attrValues linuxHosts);

      forAllSystems = f: inputs.nixpkgs.lib.genAttrs (linuxSystems ++ darwinSystems) f;

      mapHosts = f: hostsMap: builtins.mapAttrs f hostsMap;

      sharedConfiguration =
        { config, pkgs, ... }: {
          system.configurationRevision = self.rev or self.dirtyRev or null;

          nix = {
            nixPath = {
              inherit (inputs) nixpkgs;
              inherit (inputs) darwin;
              inherit (inputs) home-manager;
            };
            package = pkgs.nixVersions.git;
            settings = {
              trusted-users = [ "@admin" ];
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
            packages = with pkgs; [ pragmatapro ] ++ (lib.optionals
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
              inputs.nur.overlay
              (final: prev: {
                pragmatapro = prev.callPackage ./nix/pkgs/pragmatapro.nix { };
                hcron = prev.callPackage ./nix/pkgs/hcron.nix { };

                next-prayer = prev.callPackage
                  ./config/tmux/scripts/next-prayer/next-prayer.nix
                  { };

                notmuch = prev.notmuch.override {
                  withEmacs = false;
                };

                # Nixpkgs is outdated
                zsh-completions = prev.zsh-completions.overrideAttrs (oldAttrs: rec{
                  version = "master";
                  src = pkgs.fetchFromGitHub {
                    owner = "zsh-users";
                    repo = oldAttrs.pname;
                    rev = version;
                    sha256 = "sha256-+NWfTiiqZ7orLYRgpj7Qi1wktCHdR7mw5ohDGYleK0c=";
                  };
                });

                # Nixpkgs is outdated
                zsh-history-substring-search = prev.zsh-history-substring-search.overrideAttrs (oldAttrs: rec {
                  version = "master";
                  src = pkgs.fetchFromGitHub {
                    owner = "zsh-users";
                    repo = "zsh-history-substring-search";
                    rev = version;
                    sha256 = "sha256-1+w0AeVJtu1EK5iNVwk3loenFuIyVlQmlw8TWliHZGI=";
                  };
                });
              })

              # fix for swift 8
              # https://github.com/NixOS/nixpkgs/issues/327836#issuecomment-2292084100
              (final: prev:
                let
                  pkgsDarwin = import inputs.darwin-nixpkgs { inherit (prev) system; };
                in
                prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
                  inherit (pkgsDarwin) swift;
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
          # on your system were taken. It‘s perfectly fine and recommended to leave
          # this value at the release version of the first install of this system.
          # Before changing this value read the documentation for this option
          # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
          # https://nixos.org/manual/nixos/stable/index.html#sec-upgrading
          system.stateVersion = if pkgs.stdenv.isDarwin then 4 else "24.05"; # Did you read the comment?

          home-manager.users."${config.my.username}" = {
            home = {
              # Necessary for home-manager to work with flakes, otherwise it will
              # look for a nixpkgs channel.
              stateVersion =
                if pkgs.stdenv.isDarwin then "24.05" else config.system.stateVersion;
            };
          };

        };

      # default = (pkgs.writeShellScriptBin "foo" ''echo "foo" ''));

      darwinConfigurations = mapHosts
        (host: system: (inputs.darwin.lib.darwinSystem
          {
            # This gets passed to modules as an extra argument
            specialArgs = { inherit inputs; };
            inherit system;
            modules = [
              sharedConfiguration
              inputs.home-manager.darwinModules.home-manager
              inputs.nix-homebrew.darwinModules.nix-homebrew
              ./nix/modules/darwin
              ./nix/modules/shared
              ./nix/hosts/${host}.nix
            ];
          }))
        darwinHosts;

      nixosConfigurations = mapHosts
        (host: system: (
          inputs.nixpkgs.lib.nixosSystem {
            # This gets passed to modules as an extra argument
            specialArgs = { inherit inputs; };
            inherit system;
            modules = [
              sharedConfiguration
              inputs.home-manager.nixosModules.home-manager
              ./nix/modules/shared
              ./nix/hosts/${host}
            ];
          }
        ))
        linuxHosts;

      # @TODO: move the logic inside ./install here
      devShells = forAllSystems (system:
        let
          pkgs = inputs.nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            name = "dotfiles";
            buildInputs = with pkgs; [
              go
              gopls
              go-tools # staticcheck, etc...
              gomodifytags
              gotools # goimports
              typos
              typos-lsp
            ];
            # shellHook = ''echo "hi"'';
          };
        });
    in
    {
      inherit darwinConfigurations nixosConfigurations devShells;
    } // mapHosts
      # for convenience
      # nix build './#darwinConfigurations.pandoras-box.system'
      # vs
      # nix build './#pandoras-box'
      # Move them to `outputs.packages.<system>.name`
      (host: _: self.darwinConfigurations.${host}.system)
      darwinHosts;
}
