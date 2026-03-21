let
  module = {
    generic = {
      pkgs,
      lib,
      ...
    }: {
      config = with lib; {
        my.user.packages = with pkgs; [zk];
      };
    };

    homeManager = _: {
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
