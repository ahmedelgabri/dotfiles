let
  module = {
    darwin =
      {
        pkgs,
        lib,
        ...
      }:
      {
        config = with lib; {
          homebrew.casks = [ "iina" ];
          my.user.packages = with pkgs; [ mpv ];
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
          my.user.packages = with pkgs; [ mpv ];
        };
      };

    homeManager =
      { config, myConfig, ... }:
      {
        xdg.configFile = config.lib.file.mkOutOfStoreTree {
          source = ../../../../config/mpv;
          sourceRoot = "${myConfig.dotfilesDir}/config/mpv";
          targetRoot = "mpv";
        };
      };
  };
in
{
  flake = {
    modules = {
      darwin.mpv = module.darwin;
      nixos.mpv = module.nixos;
      homeManager.mpv = module.homeManager;
    };
  };
}
