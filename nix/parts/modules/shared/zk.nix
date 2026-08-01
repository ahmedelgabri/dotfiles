let
  module = {
    generic =
      { pkgs, ... }:
      {
        my.user.packages = with pkgs; [ zk ];
      };

    homeManager =
      { config, myConfig, ... }:
      {
        xdg.configFile =
          config.lib.file.mkOutOfStoreTree {
            source = ../../../../config/zk/templates;
            sourceRoot = "${myConfig.dotfilesDir}/config/zk/templates";
            targetRoot = "zk/templates";
          }
          // {
            "zk/config.toml".source =
              config.lib.file.mkOutOfStoreSymlink "${myConfig.dotfilesDir}/config/zk/config.toml";
          };
      };
  };
in
{
  flake = {
    modules = {
      generic.zk = module.generic;
      homeManager.zk = module.homeManager;
    };
  };
}
