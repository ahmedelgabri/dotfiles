{inputs, ...}: {
  flake.overlays.default = final: prev:
    {
      pragmatapro = prev.callPackage ../../pkgs/pragmatapro.nix {};
      hcron = prev.callPackage ../../pkgs/hcron.nix {};

      next-prayer = prev.callPackage ../../../config/tmux/scripts/next-prayer/next-prayer.nix {};

      notmuch = prev.notmuch.override {
        withEmacs = false;
      };

      pure-prompt = prev.pure-prompt.overrideAttrs (old: {
        patches = (old.patches or []) ++ [../../patches/pure.patch];
      });

      zsh-history-substring-search = prev.zsh-history-substring-search.overrideAttrs (_: {
        version = "latest";
        src = inputs.zsh-history-substring-search;
      });

      zsh-completions = prev.zsh-completions.overrideAttrs (_: {
        version = "latest";
        src = inputs.zsh-completions;
      });

      inherit (inputs.gh-gfm-preview.packages.${prev.stdenv.hostPlatform.system}) gh-gfm-preview;
      inherit (inputs.git-wt.packages.${prev.stdenv.hostPlatform.system}) git-wt;
      inherit (inputs.ccpeek.packages.${prev.stdenv.hostPlatform.system}) ccpeek;
      atuin = inputs.atuin.packages.${prev.stdenv.hostPlatform.system}.default;
    }
    // prev.lib.optionalAttrs prev.stdenv.isDarwin {
      sb = prev.callPackage ../../pkgs/sb.nix {};
    };
}
