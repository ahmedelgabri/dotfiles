let
  module = {
    generic = {
      pkgs,
      lib,
      ...
    }: {
      config = with lib; {
        my.env.RIPGREP_CONFIG_PATH = "$XDG_CONFIG_HOME/ripgrep/config";
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
