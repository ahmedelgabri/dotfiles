let
  module = {
    homeManager =
      { config, ... }:
      {
        home.file.".ssh/config".source =
          config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.dotfiles/config/.ssh/config";
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
