let
  module = {
    darwin = _: {
      config = {
        homebrew.casks = [ "ghostty@tip" ];
      };
    };

    nixos =
      {
        pkgs,
        lib,
        ...
      }:
      {
        config = with lib; {
          my.user.packages = with pkgs; [ ghostty ];
        };
      };

    homeManager =
      { config, myConfig, ... }:
      {
        xdg.configFile = config.lib.file.mkOutOfStoreTree {
          source = ../../../../config/ghostty;
          sourceRoot = "${myConfig.dotfilesDir}/config/ghostty";
          targetRoot = "ghostty";
        };
      };
  };
in
{
  flake = {
    modules = {
      darwin.ghostty = module.darwin;
      nixos.ghostty = module.nixos;
      homeManager.ghostty = module.homeManager;
    };
  };
}
