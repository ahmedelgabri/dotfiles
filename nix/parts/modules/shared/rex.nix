let
  # Rex is a beta macOS app that is not in nixpkgs, so this feature only links
  # its config; the app itself is installed by hand.
  module = {
    homeManager =
      { config, myConfig, ... }:
      {
        xdg.configFile."rex".source =
          config.lib.file.mkOutOfStoreSymlink "${myConfig.dotfilesDir}/config/rex";
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
