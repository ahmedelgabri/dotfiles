let
  module = {
    homeManager =
      { config, ... }:
      let
        dotfilesConfig = "${config.home.homeDirectory}/.dotfiles/config";
        mkOutOfStoreSymlink = config.lib.file.mkOutOfStoreSymlink;
      in
      {
        home.file = {
          ".gemrc".source = mkOutOfStoreSymlink "${dotfilesConfig}/.gemrc";
          ".curlrc".source = mkOutOfStoreSymlink "${dotfilesConfig}/.curlrc";
          ".ignore".source = mkOutOfStoreSymlink "${dotfilesConfig}/.ignore";
          ".psqlrc".source = mkOutOfStoreSymlink "${dotfilesConfig}/.psqlrc";
        };

        xdg.configFile."fd/ignore".source = mkOutOfStoreSymlink "${dotfilesConfig}/.ignore";
      };
  };
in
{
  flake = {
    modules = {
      homeManager.misc = module.homeManager;
    };
  };
}
