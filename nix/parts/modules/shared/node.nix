let
  module = {
    generic = {
      lib,
      config,
      ...
    }: let
      inherit (config.home-manager.users."${config.my.username}") xdg;
    in {
      config = with lib; {
        # I don't install any packages here because I use shell.nix for each project, so no need for globals
        environment.variables = with config.my; {
          NODE_REPL_HISTORY = "${xdg.cacheHome}/node_repl_history";
          NPM_CONFIG_EDITOR = "$EDITOR";
          NPM_CONFIG_INIT_AUTHOR_NAME = name;
          NPM_CONFIG_INIT_AUTHOR_EMAIL = email;
          NPM_CONFIG_INIT_AUTHOR_URL = website;
          NPM_CONFIG_INIT_LICENSE = "MIT";
          NPM_CONFIG_INIT_VERSION = "0.0.0";
        };

        environment = {
          shellAliases = {
            y = "yarn";
            p = "pnpm";
          };
        };

        age.secrets = {
          npmrc = {
            file = ../../../secrets/npmrc.age;
            path = "${config.my.user.home}/.npmrc";
            owner = config.my.username;
            mode = "600";
          };
        };
      };
    };

    homeManager = _: {
      xdg.configFile = {
        "pnpm" = {
          recursive = true;
          source = ../../../../config/pnpm;
        };
      };
    };
  };
in {
  flake.modules.generic.node = module.generic;
  flake.modules.homeManager.node = module.homeManager;
}
