let
  module = {
    generic = {
      pkgs,
      lib,
      config,
      ...
    }: {
      config = with lib; {
        my.user.packages = with pkgs; [zk];
      };
    };

    homeManager = {
      lib,
      myConfig,
      ...
    }:
      with lib; {
        xdg.configFile = {
          "zk/config.toml".source = ../../../../config/zk/config.toml;
          "zk/templates" = {
            recursive = true;
            source = ../../../../config/zk/templates;
          };
        };
      };
  };
in {
  flake = {
    modules = {
      generic.zk = module.generic;
      homeManager.zk = module.homeManager;
    };
  };
}
