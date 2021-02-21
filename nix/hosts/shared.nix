{ config, pkgs, lib, inputs, options, ... }: {
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
    overlays = [
      (final: prev: {
        pragmatapro = (prev.callPackage ../pkgs/pragmatapro.nix { });

        neuron-notes =
          (prev.callPackage "${inputs.neuron-notes-master}/project.nix"
            { }).neuron;

        comma = import inputs.comma { inherit (prev) pkgs; };

        neovim-unwrapped = prev.neovim-unwrapped.overrideAttrs (oldAttrs: {
          version = "master";
          src = inputs.neovim-nightly;
          buildInputs = oldAttrs.buildInputs ++ [ pkgs.tree-sitter ];
        });

        pure-prompt = prev.pure-prompt.overrideAttrs
          (old: { patches = (old.patches or [ ]) ++ [ ./pure-zsh.patch ]; });

        python3 = prev.python3.override {
          packageOverrides = final: prev: {
            python-language-server =
              prev.python-language-server.overridePythonAttrs
              (old: rec { doCheck = false; });
          };
        };
      })
    ];
  };

  time.timeZone = config.my.timezone;
}
