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
      { config, myConfig, ... }:
      {
        xdg.configFile.".bunfig.toml".source =
          config.lib.file.mkOutOfStoreSymlink "${myConfig.dotfilesDir}/config/bun/.bunfig.toml";
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
