let
  module = {
    generic =
      { pkgs, ... }:
      {
        my.user.packages = with pkgs; [ zk ];
      };

    homeManager =
      { config, ... }:
      {
        xdg.configFile =
          config.lib.file.mkOutOfStoreTree {
            source = ../../../../config/zk/templates;
            sourceRoot = "${config.home.homeDirectory}/.dotfiles/config/zk/templates";
            targetRoot = "zk/templates";
          }
          // {
            "zk/config.toml".source =
              config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/config/zk/config.toml";
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
