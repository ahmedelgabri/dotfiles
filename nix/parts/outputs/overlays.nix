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
    };
}
