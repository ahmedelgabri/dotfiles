let
  module = {
    homeManager =
      { config, myConfig, ... }:
      {
        home.file.".ssh/config".source =
          config.lib.file.mkOutOfStoreSymlink "${myConfig.dotfilesDir}/config/.ssh/config";
      };
  };
in
{
  flake = {
    modules = {
      homeManager.ssh = module.homeManager;
    };
  };
}
