{ pkgs, lib, config, inputs, ... }:

let

  cfg = config.my.modules.node;
in
{
  options = with lib; {
    my.modules.node = {
      enable = mkEnableOption ''
        Whether to enable node module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable (mkMerge [
      (if (builtins.hasAttr "homebrew" options) then {
        # workaround for now see https://github.com/NixOS/nixpkgs/issues/145634
        homebrew.brews = [ "yarn" "pnpm" ];
      } else { })
      {
        my = {
          env = with config.my; {
            NODE_REPL_HISTORY = "$XDG_CACHE_HOME/node_repl_history";
            NPM_CONFIG_EDITOR = "$EDITOR";
            NPM_CONFIG_INIT_AUTHOR_NAME = name;
            NPM_CONFIG_INIT_AUTHOR_EMAIL = email;
            NPM_CONFIG_INIT_AUTHOR_URL = website;
            NPM_CONFIG_INIT_LICENSE = "MIT";
            NPM_CONFIG_INIT_VERSION = "0.0.0";
          };

          user = {
            packages = with pkgs; [
              nodePackages.svgo
            ];
          };

          hm.file = {
            ".npmrc" = {
              source = ../../../config/.npmrc;
            };
          };
        };
      }
    ]);
}
