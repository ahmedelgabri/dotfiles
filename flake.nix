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

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Extras
    # nixos-hardware.url = "github:nixos/nixos-hardware";
  };

  outputs = {
    self,
    treefmt-nix,
    ...
  } @ inputs: let
    darwinHosts = {
      "pandoras-box" = "x86_64-darwin";
      "alcantara" = "aarch64-darwin";
      "rocket" = "aarch64-darwin";
    };

    darwinSystems = inputs.nixpkgs.lib.unique (inputs.nixpkgs.lib.attrValues darwinHosts);

    linuxHosts = {
      "nixos" = "x86_64-linux";
    };

    linuxSystems = inputs.nixpkgs.lib.unique (inputs.nixpkgs.lib.attrValues linuxHosts);

    forAllSystems = f: inputs.nixpkgs.lib.genAttrs (linuxSystems ++ darwinSystems) f;

    mapHosts = f: hostsMap: builtins.mapAttrs f hostsMap;

    sharedConfiguration = {
      config,
      pkgs,
      ...
    }: {
      system.configurationRevision = self.rev or self.dirtyRev or null;

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
              noto-fonts-cjk
              noto-fonts-emoji
              # liberation_ttf
              fira-code
              fira-code-symbols
              mplus-outline-fonts
              dina-font
              proggyfonts
              (nerdfonts.override {fonts = ["FiraCode" "DroidSansMono"];})
            ]);
      };

      nixpkgs = {
        config = {allowUnfree = true;};
        overlays = [
          inputs.yazi.overlays.default
          inputs.nur.overlays.default
          (final: prev: {
            pragmatapro = prev.callPackage ./nix/pkgs/pragmatapro.nix {};
            hcron = prev.callPackage ./nix/pkgs/hcron.nix {};

            next-prayer =
              prev.callPackage
              ./config/tmux/scripts/next-prayer/next-prayer.nix
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
      # on your system were taken. It‘s perfectly fine and recommended to leave
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

    darwinConfigurations =
      mapHosts
      (host: system: (inputs.darwin.lib.darwinSystem
        {
          # This gets passed to modules as an extra argument
          specialArgs = {inherit inputs;};
          inherit system;
          modules = [
            sharedConfiguration
            inputs.home-manager.darwinModules.home-manager
            inputs.nix-homebrew.darwinModules.nix-homebrew
            ./nix/modules/shared
            ./nix/modules/darwin
            ./nix/hosts/${host}.nix
          ];
        }))
      darwinHosts;

    nixosConfigurations =
      mapHosts
      (host: system: (
        inputs.nixpkgs.lib.nixosSystem {
          # This gets passed to modules as an extra argument
          specialArgs = {inherit inputs;};
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

    formatter = forAllSystems (system: let
      treefmtEval = treefmt-nix.lib.evalModule
      inputs.nixpkgs.legacyPackages.${system}
      ./treefmt.nix;
    in
      treefmtEval.config.build.wrapper);

    checks = forAllSystems (system: let
      treefmtEval = treefmt-nix.lib.evalModule
      inputs.nixpkgs.legacyPackages.${system}
      ./treefmt.nix;
    in {
      formatting = treefmtEval.config.build.check self;
    });

    apps = forAllSystems (system: let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
      utils = pkgs.writeShellApplication {
        name = "utils";
        text = builtins.readFile scripts/utils;
      };
      bootstrap = pkgs.writeShellApplication {
        name = "bootstrap";
        runtimeInputs = [pkgs.git];
        text = ''
          # shellcheck disable=SC1091
          source ${pkgs.lib.getExe utils}
          ${builtins.readFile scripts/${system}_bootstrap}
        '';
      };
    in {
      default = {
        type = "app";
        program = pkgs.lib.getExe bootstrap;
      };
    });

    # @TODO: move the logic inside ./install here
    devShells = forAllSystems (system: let
      pkgs = inputs.nixpkgs.legacyPackages.${system};
    in {
      default = pkgs.mkShell {
        name = "dotfiles";
        packages = with pkgs; [
          typos
          typos-lsp
          alejandra
        ];
      };
      go = pkgs.mkShell {
        name = "dotfiles-go";
        packages = with pkgs; [
          go
          gopls
          go-tools # staticcheck, etc...
          gomodifytags
          gotools # goimports
        ];
      };
    });
  in
    {
      inherit
        darwinConfigurations
        nixosConfigurations
        devShells
        formatter
        apps
        checks
        ;
      templates = import ./templates;
    }
    // mapHosts
    # for convenience
    # nix build './#darwinConfigurations.pandoras-box.system'
    # vs
    # nix build './#pandoras-box'
    # Move them to `outputs.packages.<system>.name`
    (host: _: self.darwinConfigurations.${host}.system)
    darwinHosts;
}
