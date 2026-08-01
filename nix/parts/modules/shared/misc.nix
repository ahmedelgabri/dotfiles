let
  module = {
    homeManager =
      { config, myConfig, ... }:
      let
        dotfilesConfig = "${myConfig.dotfilesDir}/config";
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
