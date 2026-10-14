let
  # Rex is a beta macOS app that is not in nixpkgs, so this feature only links
  # its config; the app itself is installed by hand.
  module = {
    homeManager =
      { config, myConfig, ... }:
      {
        xdg.configFile = config.lib.file.mkOutOfStoreTree {
          source = ../../../../config/rex;
          sourceRoot = "${myConfig.dotfilesDir}/config/rex";
          targetRoot = "rex";
        };
      };
  };
in
{
  flake = {
    modules = {
      homeManager.rex = module.homeManager;
    };
  };
}
