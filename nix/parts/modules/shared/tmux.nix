let
  module = {
    generic =
      {
        pkgs,
        lib,
        ...
      }:
      {
        config = with lib; {
          environment.shellAliases.tmux = "direnv exec / tmux";

          my.user.packages = with pkgs; [
            tmux
            next-prayer
          ];
        };
      };

    homeManager =
      { config, myConfig, ... }:
      {
        xdg.configFile = config.lib.file.mkOutOfStoreTree {
          source = ../../../../config/tmux;
          sourceRoot = "${myConfig.dotfilesDir}/config/tmux";
          targetRoot = "tmux";
        };
      };
  };
in
{
  flake = {
    modules = {
      generic.tmux = module.generic;
      homeManager.tmux = module.homeManager;
    };
  };
}
