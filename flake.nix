# As a first step, I will try to symlink my configs as much as possible then
# migrate the configs to Nix
#
# https://nixcloud.io/ for Nix syntax
# https://nix.dev/
# https://nix-community.github.io/awesome-nix/
# https://discourse.nixos.org/t/home-manager-equivalent-of-apt-upgrade/8424/3
# https://www.reddit.com/r/NixOS/comments/jmom4h/new_neofetch_nixos_logo/gayfal2/
# https://www.youtube.com/user/elitespartan117j27/videos?view=0&sort=da&flow=grid
# https://www.youtube.com/playlist?list=PLRGI9KQ3_HP_OFRG6R-p4iFgMSK1t5BHs
# https://www.reddit.com/r/NixOS/comments/k9xwht/best_resources_for_learning_nixos/
# https://www.reddit.com/r/NixOS/comments/k8zobm/nixos_preferred_packages_flow/
# https://www.reddit.com/r/NixOS/comments/j4k2zz/does_anyone_use_flakes_to_manage_their_entire/
#
# Sample repos
# https://github.com/teoljungberg/dotfiles/tree/master/nixpkgs (contains custom hammerspoon & vim )
# https://github.com/jwiegley/nix-config (nice example)
# https://github.com/hardselius/dotfiles (good readme on steps to do for install)
# https://github.com/nuance/dotfiles
#
# With flakes
# https://github.com/hlissner/dotfiles
# https://github.com/mjlbach/nix-dotfiles
# https://github.com/thpham/nix-configs/blob/e46a15f69f/default.nix (nice example of how to build)
# https://github.com/sandhose/nixconf
# https://github.com/cideM/dotfiles (darwin, NixOS, home-manager)
# https://github.com/monadplus/nixconfig
# https://github.com/jamesottaway/dotfiles (Darwin, NixOS, home-manager)
# https://github.com/malob/nixpkgs (Darwin, home-manager, homebrew in nix & PAM, this is a great example)
# https://github.com/kclejeune/system (nice example)
# https://github.com/mrkuz/nixos
#

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

    neovim-nightly = {
      url = "github:neovim/neovim";
      flake = false;
    };

    z = {
      url = "github:rupa/z";
      flake = false;
    };

    n = {
      url = "github:tj/n";
      flake = false;
    };

    comma = {
      url = "github:Shopify/comma";
      flake = false;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ttrv = {
      url = "github:tildeclub/ttrv";
      flake = false;
    };

    lookatme = {
      url = "github:d0c-s4vage/lookatme";
      flake = false;
    };

    weechat-scripts = {
      url = "github:weechat/scripts";
      flake = false;
    };

    neuron-notes-master = {
      url = "github:srid/neuron";
      flake = false;
    };

    # Extras
    # nixos-hardware.url = "github:nixos/nixos-hardware";
  };

  outputs = { self, ... }@inputs:
    let
      sharedHostsConfig = { config, pkgs, lib, options, ... }: {
        nix = {
          package = pkgs.nixFlakes;
          extraOptions = "experimental-features = nix-command flakes";
          binaryCaches = [
            "https://cache.nixos.org"
            "https://nix-community.cachix.org"
            "https://nixpkgs.cachix.org"
            "https://srid.cachix.org"
          ];
          binaryCachePublicKeys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE="
            "srid.cachix.org-1:MTQ6ksbfz3LBMmjyPh0PLmos+1x+CdtJxA/J2W+PQxI="
          ];
          gc = {
            automatic = true;
            options = "--delete-older-than 3d";
          };
        };

        fonts = (lib.mkMerge [
          # [note] Remove this condition when `nix-darwin` aligns with NixOS
          (if (builtins.hasAttr "fontDir" options.fonts) then {
            fontDir.enable = true;
          } else {
            enableFontDir = true;
          })
          { fonts = with pkgs; [ pragmatapro ]; }
        ]);

        nixpkgs = {
          config = { allowUnfree = true; };
          overlays = [ self.overlay ];
        };

        time.timeZone = config.my.timezone;
      };

    in
    {
      overlay = (final: prev: {
        pragmatapro = (prev.callPackage ./nix/pkgs/pragmatapro.nix { });

        neuron-notes =
          (prev.callPackage "${inputs.neuron-notes-master}/project.nix"
            { }).neuron;

        comma = import inputs.comma { inherit (prev) pkgs; };

        neovim-unwrapped = prev.neovim-unwrapped.overrideAttrs (oldAttrs: {
          version = "master";
          src = inputs.neovim-nightly;
          buildInputs = oldAttrs.buildInputs ++ [ prev.pkgs.tree-sitter ];
        });

        pure-prompt = prev.pure-prompt.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ./nix/hosts/pure-zsh.patch ];
        });

        python3 = prev.python3.override {
          packageOverrides = final: prev: {
            python-language-server =
              prev.python-language-server.overridePythonAttrs
                (old: rec { doCheck = false; });
          };
        };
      });

      darwinConfigurations = {
        "pandoras-box" = inputs.darwin.lib.darwinSystem {
          inputs = inputs;
          modules = [
            inputs.home-manager.darwinModules.home-manager
            ./nix/modules/shared
            sharedHostsConfig
            ./nix/hosts/pandoras-box.nix
          ];
        };

        "ahmed-at-work" = inputs.darwin.lib.darwinSystem {
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

      # [todo] very alpha, needs work
      nixosConfigurations = {
        "nixos" = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            inputs.home-manager.nixosModules.home-manager
            ./nix/hosts/shared.nix
            ./nix/hosts/nixos
          ];
        };
      };
    };
}
