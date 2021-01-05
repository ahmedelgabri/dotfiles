{ config, pkgs, lib, inputs, ... }: {
  nix = {
    package = pkgs.nixFlakes;
    extraOptions = "experimental-features = nix-command flakes";
    binaryCaches = [
      "https://cache.nixos.org"
      # "https://nix-community.cachix.org"
      "https://nixpkgs.cachix.org"
    ];
    binaryCachePublicKeys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs.cachix.org-1:q91R6hxbwFvDqTSDKwDAV4T5PxqXGxswD8vhONFMeOE="
    ];
    gc = {
      automatic = true;
      options = "--delete-older-than 3d";
    };
  };

  imports = [ ../modules/shared ];

  my = {
    shell.enable = true;
    git.enable = true;
    mail = { enable = true; };
    aerc = { enable = true; };
    gpg.enable = true;
    ssh.enable = true;
    kitty.enable = true;
    alacritty.enable = true;
    bat.enable = true;
    lf.enable = true;
    mpv.enable = true;
    newsboat.enable = true;
    python.enable = true;
    ripgrep.enable = true;
    tmux.enable = true;
    tuir.enable = true;
    youtube-dl.enable = true;
    misc.enable = true;
    vim.enable = true;

    node.enable = true;
    java.enable = false;
    kotlin.enable = true;
    weechat.enable = true;
    go.enable = true;
    rust.enable = true;
    rescript.enable = true;
    gui.enable = true;
    clojure.enable = true;
  };

  nixpkgs = {
    config = { allowUnfree = true; };
    overlays = [
      # (import inputs.comma { inherit pkgs; })
      (final: prev: {
        neovim-unwrapped = prev.neovim-unwrapped.overrideAttrs (oldAttrs: {
          version = "master";
          src = inputs.neovim-nightly;
          buildInputs = oldAttrs.buildInputs ++ [ pkgs.tree-sitter ];
        });

        pure-prompt = prev.pure-prompt.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ../overlays/pure-zsh.patch ];
        });

        python3 = prev.python3.override {
          packageOverrides = final: prev: {
            python-language-server =
              prev.python-language-server.overridePythonAttrs
              (old: rec { doCheck = false; });
          };
        };

        # https://github.com/NixOS/nixpkgs/issues/106506#issuecomment-742639055
        weechat = prev.weechat.override {
          configure = { availablePlugins, ... }: {
            plugins = with availablePlugins;
              [ (perl.withPackages (p: [ p.PodParser ])) ] ++ [ python ];
            scripts = with prev.weechatScripts;
              [ wee-slack ]
              ++ final.stdenv.lib.optionals (!final.stdenv.isDarwin)
              [ weechat-notify-send ];
          };
        };
      })
    ];
  };

  time.timeZone = config.settings.timezone;

  users.users.${config.settings.username} = {
    description = "Primary user account";
    shell = [ pkgs.zsh ];
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${config.settings.username} = {
      xdg = { enable = true; };
      home = {
        # Necessary for home-manager to work with flakes, otherwise it will
        # look for a nixpkgs channel.
        stateVersion =
          if pkgs.stdenv.isDarwin then "20.09" else config.system.stateVersion;
      };
      programs = {
        # Let Home Manager install and manage itself.
        home-manager.enable = true;
      };
    };
  };
}
