let
  module = {
    generic =
      {
        pkgs,
        lib,
        config,
        ...
      }:
      let
        inherit (config.home-manager.users."${config.my.username}") xdg;
      in
      {
        config = with lib; {
          environment = {
            shellAliases.cat = "bat";
            variables.BAT_CONFIG_PATH = "${xdg.configHome}/bat/config";
          };

          my.user.packages = with pkgs; [ bat ];
        };
      };

    homeManager =
      { config, ... }:
      {
        xdg.configFile = config.lib.file.mkOutOfStoreTree {
          source = ../../../../config/bat;
          sourceRoot = "${config.home.homeDirectory}/.dotfiles/config/bat";
          targetRoot = "bat";
        };
      };
  };
in
{
  flake = {
    modules = {
      generic.bat = module.generic;
      homeManager.bat = module.homeManager;
    };
  };
}
