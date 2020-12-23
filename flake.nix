# As a first step, I will try to symlink my configs as much as possible then
# migrate the configs to Nix
#
# https://nixcloud.io/ for Nix syntax
# https://discourse.nixos.org/t/home-manager-equivalent-of-apt-upgrade/8424/3
# https://www.mathiaspolligkeit.de/dev/exploring-nix-on-macos/
# https://catgirl.ai/log/nixos-experience/
# https://kevincox.ca/2020/09/06/switching-to-desktop-nixos/
# https://www.reddit.com/r/NixOS/comments/jmom4h/new_neofetch_nixos_logo/gayfal2/
# https://ghedam.at/15978/an-introduction-to-nix-shell
# https://foo-dogsquared.github.io/blog/posts/moving-into-nixos/
# https://www.youtube.com/user/elitespartan117j27/videos?view=0&sort=da&flow=grid
# https://www.youtube.com/playlist?list=PLRGI9KQ3_HP_OFRG6R-p4iFgMSK1t5BHs
# https://www.reddit.com/r/NixOS/comments/k9xwht/best_resources_for_learning_nixos/
# https://www.reddit.com/r/NixOS/comments/k8zobm/nixos_preferred_packages_flow/
#
# Sample repos
# https://github.com/malloc47/config (very simple!)
# https://github.com/wbadart/dotfiles (simple)
# https://github.com/srid/nix-config
# https://github.com/yevhenshymotiuk/darwin-home (this is what I should aim for as a start)
# https://github.com/rummik/nixos-config
# https://github.com/teoljungberg/dotfiles/tree/master/nixpkgs (contains custom hammerspoon & vim )
# https://github.com/gmarmstrong/dotfiles
# https://github.com/jwiegley/nix-config (nice example)
# https://github.com/hardselius/dotfiles (good readme on steps to do for install)
#
# With flakes
# https://github.com/hlissner/dotfiles
# https://github.com/kclejeune/system (nice example)
# https://github.com/mjlbach/nix-dotfiles
# https://github.com/thpham/nix-configs/blob/e46a15f69f/default.nix (nice example of how to build)
# https://github.com/sandhose/nixconf

{
  description = "My config";

  inputs = {
    nixpkgs.url = "nixpkgs/master";
    nixpkgs-unstable.url = "nixpkgs/master";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:lnl7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly = {
      url = "github:neovim/neovim/master";
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

    # Extras
    # nixos-hardware.url = "github:nixos/nixos-hardware";
  };

  outputs = { self, ... }@inputs:
    let nixpkgsCfg = { allowUnfree = true; };

    in {
      darwinConfigurations = {
        "pandoras-box" = inputs.darwin.lib.darwinSystem {
          inputs = inputs;
          modules = [
            inputs.home-manager.darwinModules.home-manager
            ./nix/shared
            ./nix/darwin
          ];
        };
      };

      nixosConfigurations = {
        "vagrant-machine" = inputs.nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };
          modules = [
            inputs.home-manager.nixosModules.home-manager
            ./nix/shared
            ./nix/nixos
          ];
        };
      };
    };
}
