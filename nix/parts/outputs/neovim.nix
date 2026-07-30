# Standalone, fully configured neovim: `nix run .#neovim`.
#
# The lua config in config/nvim is baked into the store and the plugin set is
# built from config/nvim/nvim-pack-lock.json, so the same lock file drives
# vim.pack at runtime (hosts) and this package. fetchGit with a full commit
# rev is allowed in pure eval, so no --impure is needed. pack.lua detects the
# wrapper via `vim.g.nix_info_plugin_name` and skips vim.pack entirely.
{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      module =
        {
          config,
          wlib,
          lib,
          pkgs,
          ...
        }:
        let
          lock = builtins.fromJSON (builtins.readFile ../../../config/nvim/nvim-pack-lock.json);

          # Specs that pin a `version = '<branch>'` differing from the repo's
          # default branch; their locked revs are only reachable from that
          # branch, so fetchGit needs the ref spelled out.
          # branchRefs = {
          #   "nvim-treesitter" = "main";
          #   "nvim-treesitter-textobjects" = "main";
          # };
          branchRefs = null;

          # These plugins need compiled artifacts that their vim.pack `build`
          # hooks would produce at runtime (blink.cmp's rust fuzzy matcher,
          # LuaSnip's jsregexp). Build hooks never run under nix, so take the
          # nixpkgs builds, which ship the artifacts; their revs may differ
          # from the lock file.
          prebuilt = {
            "blink.cmp" = pkgs.vimPlugins.blink-cmp;
            "LuaSnip" = pkgs.vimPlugins.luasnip;
          };

          mkNvimPlugin =
            name: plugin:
            prebuilt.${name} or (config.nvim-lib.mkPlugin name (
              builtins.fetchGit (
                {
                  url = plugin.src;
                  inherit (plugin) rev;
                  # Only the locked rev is needed; full history would clone
                  # hundreds of MB.
                  shallow = true;
                }
                // lib.optionalAttrs (branchRefs ? ${name}) { ref = branchRefs.${name}; }
              )
            ));
        in
        {
          imports = [ wlib.wrapperModules.neovim ];

          config = {
            settings.config_directory = ../../../config/nvim;

            # Everything goes to `opt/` (lazy = true) because pack.lua loads
            # each plugin with :packadd, whether eagerly or via its triggers.
            # `pname` pins the `opt/` directory name to the lock entry name,
            # which is what pack.lua's spec_name() derives for :packadd.
            specs = builtins.mapAttrs (name: plugin: {
              lazy = true;
              pname = name;
              data = mkNvimPlugin name plugin;
            }) lock.plugins;

            runtimePkgs =
              import ../modules/shared/vim-tools.nix pkgs
              ++ [
                # nvim-treesitter downloads and compiles parsers at runtime
                pkgs.git
                pkgs.curl
              ]
              ++ lib.optionals pkgs.stdenv.isLinux [ pkgs.gcc ];
          };
        };
    in
    {
      packages.neovim = (inputs.nix-wrapper-modules.lib.evalModule module).config.wrap {
        inherit pkgs;
      };
    };
}
