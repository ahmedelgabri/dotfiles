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

    homeManager = _: {
      xdg.configFile = {
        ".bunfig.toml" = {
          recursive = true;
          source = ../../../../config/bun/.bunfig.toml;
        };
      };
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
