{inputs, ...}: {
  flake.overlays.default = final: prev: {
    pragmatapro = prev.callPackage ../../pkgs/pragmatapro.nix {};
    hcron = prev.callPackage ../../pkgs/hcron.nix {};

    next-prayer = prev.callPackage ../../../config/tmux/scripts/next-prayer/next-prayer.nix {};

    notmuch = prev.notmuch.override {
      withEmacs = false;
    };

    pure-prompt = prev.pure-prompt.overrideAttrs (old: {
      patches = (old.patches or []) ++ [../../patches/pure.patch];
    });

    zsh-history-substring-search = prev.zsh-history-substring-search.overrideAttrs (oldAttrs: rec {
      version = "master";
      src = prev.fetchFromGitHub {
        owner = "zsh-users";
        repo = oldAttrs.pname;
        rev = version;
        sha256 = "sha256-KHujL1/TM5R3m4uQh2nGVC98D6MOyCgQpyFf+8gjKR0=";
      };
    });

    zsh-completions = prev.zsh-completions.overrideAttrs (oldAttrs: rec {
      version = "master";
      src = prev.fetchFromGitHub {
        owner = "zsh-users";
        repo = oldAttrs.pname;
        rev = version;
        sha256 = "sha256-JVX+gWLvcnln4pEJ/d4I7iIfWXHZ+zu8MRMGIslh/Fw=";
      };
    });

    inherit (inputs.gh-gfm-preview.packages.${prev.stdenv.hostPlatform.system}) gh-gfm-preview;
    inherit (inputs.git-wt.packages.${prev.stdenv.hostPlatform.system}) git-wt;
    inherit (inputs.ccpeek.packages.${prev.stdenv.hostPlatform.system}) ccpeek;
    atuin = inputs.atuin.packages.${prev.stdenv.hostPlatform.system}.default;
  };
}
