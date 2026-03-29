let
  module = {
    generic = {
      pkgs,
      lib,
      config,
      ...
    }: let
      inherit (config.home-manager.users."${config.my.username}") xdg;
    in {
      config = with lib; {
        environment.variables.RIPGREP_CONFIG_PATH = "${xdg.configHome}/ripgrep/config";
        my.user.packages = with pkgs; [ripgrep];
      };
    };

    homeManager = _: {
      xdg.configFile."ripgrep" = {
        recursive = true;
        source = ../../../../config/ripgrep;
      };
    };
  };
in {
  flake = {
    modules = {
      generic.ripgrep = module.generic;
      homeManager.ripgrep = module.homeManager;
    };
  };
}
