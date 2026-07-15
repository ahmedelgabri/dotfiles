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
          my.user.packages = with pkgs; [
            bun
          ];

          environment = {
            shellAliases = {
              b = "bun";
            };
          };
        };
      };

    homeManager =
      { config, ... }:
      {
        xdg.configFile.".bunfig.toml".source =
          config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/config/bun/.bunfig.toml";
      };
  };
in
{
  flake = {
    modules = {
      generic.bun = module.generic;
      homeManager.bun = module.homeManager;
    };
  };
}
