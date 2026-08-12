{ inputs, ... }:
{
  flake.overlays.default =
    final: prev:
    {
      pragmatapro = prev.callPackage ../../pkgs/pragmatapro.nix { };
      hcron = prev.callPackage ../../pkgs/hcron.nix { };

      next-prayer = prev.callPackage ../../pkgs/next-prayer/next-prayer.nix { };

      notmuch = prev.notmuch.override {
        withEmacs = false;
      };

      llm-agents = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system};

      inherit (inputs.gh-gfm-preview.packages.${prev.stdenv.hostPlatform.system}) gh-gfm-preview;
      inherit (inputs.git-wt.packages.${prev.stdenv.hostPlatform.system}) git-wt;
      inherit (inputs.ccpeek.packages.${prev.stdenv.hostPlatform.system}) ccpeek;
      inherit (inputs.tap.packages.${prev.stdenv.hostPlatform.system}) tap;
      atuin = inputs.atuin.packages.${prev.stdenv.hostPlatform.system}.default;
      nixfmt-rs = inputs.nixfmt-rs.packages.${prev.stdenv.hostPlatform.system}.default;
    }
    // prev.lib.optionalAttrs prev.stdenv.isDarwin {
      sb = prev.callPackage ../../pkgs/sb.nix { };

      # aerc 0.22.0 dropped fsevents.FileEvents (to fix vsplit rerendering)
      # but its watch loop still filters on file-level Item* flags, which
      # directory-granularity events never carry. Every event is dropped, so
      # the maildir view goes stale until restart. Forward directory events
      # so the workers rescan. https://todo.sr.ht/~rjarry/aerc
      aerc = prev.aerc.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ../../pkgs/aerc-darwin-fsevents.patch ];
      });
    };
}
