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
        environment = {
          shellAliases.cat = "bat";
          zshGlobalAliases = {
            "-h" = "-h 2>&1 | bat --language=help --style=plain";
            "--help" = "--help 2>&1 | bat --language=help --style=plain";
          };
          variables.BAT_CONFIG_PATH = "${xdg.configHome}/bat/config";
        };

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
