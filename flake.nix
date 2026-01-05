# Some useful resources
#
# https://nix.dev/
# https://nixos.org/guides/nix-pills/
# https://nix-community.github.io/awesome-nix/
# https://serokell.io/blog/practical-nix-flakes
# https://zero-to-nix.com/
# https://wiki.nixos.org/wiki/Flakes
# https://rconybea.github.io/web/nix/nix-for-your-own-project.html
{
  description = "~ 🍭 ~";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    import-tree.url = "github:vic/import-tree";

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

  nixConfig = {
    # builders-use-substitutes = true;
    # connect-timeout = 300;
    # download-attempts = 3;
    # http-connections = 0;
    # use-xdg-base-directories = true;
    warn-dirty = false;

    extra-substituters = [
      "https://cache.nixos.org"
      "https://nix-community.cachix.org"
      "https://nixpkgs.cachix.org"
      "https://yazi.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE="
      "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
    ];
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} (top @ {
      config,
      withSystem,
      moduleWithSystem,
      ...
    }: {
      # https://flake.parts/debug.html
      debug = true;

      systems = [
        "x86_64-darwin"
        "aarch64-darwin"
        # "x86_64-linux"
      ];

      # Auto-import all flake-parts modules from ./nix using import-tree
      # This is the Dendritic Pattern: every .nix file is a module
      imports = [
        (inputs.import-tree ./flake-modules)
      ];

      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;

          config = {
            allowUnfree = true;
          };

          overlays = [
            inputs.yazi.overlays.default
            inputs.nur.overlays.default
            (final: prev: {
              pragmatapro = prev.callPackage "${self'}/nix/pkgs/pragmatapro.nix" {};
              hcron = prev.callPackage "${self'}/nix/pkgs/hcron.nix" {};

              next-prayer =
                prev.callPackage
                "${self'}/config/tmux/scripts/next-prayer/next-prayer.nix"
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

        formatter = pkgs.alejandra;
      };

      flake = {
        templates = import ./templates;
      };
    });
}
