let
  module = {
    generic = {
      pkgs,
      lib,
      ...
    }: {
      config = with lib; {
        environment.shellAliases.cat = "bat";

        my.env.BAT_CONFIG_PATH = "$XDG_CONFIG_HOME/bat/config";
        my.user.packages = with pkgs; [bat];
      };
    };

    homeManager = _: {
      xdg.configFile."bat" = {
        recursive = true;
        source = ../../../../config/bat;
      };
    };
  };
in {
  flake = {
    modules = {
      generic.bat = module.generic;
      homeManager.bat = module.homeManager;
    };
  };
}
