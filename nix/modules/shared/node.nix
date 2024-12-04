{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: let
  cfg = config.my.modules.node;
in {
  options = with lib; {
    my.modules.node = {
      enable = mkEnableOption ''
        Whether to enable node module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      # I don't install any packages here because I use shell.nix for each project, so no need for globals
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

        hm.file = {
          ".npmrc" = {
            source = ../../../config/.npmrc;
          };
        };
      };
    };
}
