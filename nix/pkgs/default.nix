# Custom packages as overlays
{inputs, ...}: {
  flake.overlays.default = final: prev: {
    pragmatapro = prev.callPackage ./pragmatapro.nix {};
    hcron = prev.callPackage ./hcron.nix {};

    next-prayer =
      prev.callPackage
      ../../config/tmux/scripts/next-prayer/next-prayer.nix
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
  };
}
