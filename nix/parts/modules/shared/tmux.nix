let
  module = {
    generic = {
      pkgs,
      lib,
      config,
      ...
    }: {
      config = with lib; {
        environment.shellAliases.tmux = "direnv exec / tmux";

        my.user.packages = with pkgs; [
          tmux
          next-prayer
        ];
      };
    };

    homeManager = {
      lib,
      myConfig,
      ...
    }:
      with lib; {
        xdg.configFile."tmux" = {
          recursive = true;
          source = ../../../../config/tmux;
        };
      };
  };
in {
  flake = {
    modules = {
      generic.tmux = module.generic;
      homeManager.tmux = module.homeManager;
    };
  };
}
