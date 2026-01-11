# Some useful resources
#
# https://nix.dev/
# https://nixos.org/guides/nix-pills/
# https://nix-community.github.io/awesome-nix/
# https://serokell.io/blog/practical-nix-flakes
# https://zero-to-nix.com/
# https://wiki.nixos.org/wiki/Flakes
# https://rconybea.github.io/web/nix/nix-for-your-own-project.html
# https://github.com/mightyiam/dendritic - Dendritic Pattern
# https://github.com/vic/import-tree - Auto-import modules
{
  description = "~ 🍭 ~";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
    };

    import-tree = {
      url = "github:vic/import-tree";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };

    darwin = {
      url = "github:nix-darwin/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    yazi = {
      url = "github:sxyazi/yazi";
    };

    yazi-plugins = {
      url = "github:yazi-rs/plugins";
      flake = false;
    };

    yazi-glow = {
      url = "github:Reledia/glow.yazi";
      flake = false;
    };

    nur = {
      url = "github:nix-community/nur";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gh-gfm-preview = {
      url = "github:thiagokokada/gh-gfm-preview";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    emmylua-analyzer-rust = {
      url = "github:EmmyLuaLs/emmylua-analyzer-rust";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        darwin.follows = "darwin";
        home-manager.follows = "home-manager";
      };
    };

    # Extras
    # nixos-hardware.url = "github:nixos/nixos-hardware";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;}
    (inputs.import-tree ./nix/flake-modules);
}
