{ inputs, ... }:
{
  flake.overlays.default =
    _final: prev:
    {
      pragmatapro = prev.callPackage ../../pkgs/pragmatapro.nix { };
      hcron = prev.callPackage ../../pkgs/hcron.nix { };

      next-prayer = prev.callPackage ../../pkgs/next-prayer/next-prayer.nix { };
      zh = prev.callPackage ../../pkgs/zh/zh.nix { };

      notmuch = prev.notmuch.override {
        withEmacs = false;
      };

      # markdown-oxide walks the vault without following symlinks, so notes
      # in a folder linked into the vault are never indexed.
      # https://github.com/Feel-ix-343/markdown-oxide/pull/522
      markdown-oxide = prev.markdown-oxide.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ../../pkgs/markdown-oxide-follow-symlinks.patch ];
      });

      # `zk index` walks the notebook without following symlinks, so notes in
      # a folder linked into the notebook are never indexed.
      # https://github.com/zk-org/zk/pull/769
      zk = prev.zk.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ../../pkgs/zk-follow-symlinks.patch ];
      });

      llm-agents = inputs.llm-agents.packages.${prev.stdenv.hostPlatform.system};

      inherit (inputs.gh-gfm-preview.packages.${prev.stdenv.hostPlatform.system}) gh-gfm-preview;
      inherit (inputs.git-wt.packages.${prev.stdenv.hostPlatform.system}) git-wt;
      inherit (inputs.ccpeek.packages.${prev.stdenv.hostPlatform.system}) ccpeek;
      inherit (inputs.tap.packages.${prev.stdenv.hostPlatform.system}) tap;
      nixfmt-rs = inputs.nixfmt-rs.packages.${prev.stdenv.hostPlatform.system}.default;
    }
    // prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
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
