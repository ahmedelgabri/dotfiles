let
  module =
{
  generic = {
    lib,
    config,
    ...
  }: {
    config = with lib; {};
  };

  homeManager = {
    lib,
    myConfig,
    ...
  }:
    with lib; {
      home.file = {
        ".gemrc".source = ../../../../config/.gemrc;
        ".curlrc".source = ../../../../config/.curlrc;
        ".ignore".source = ../../../../config/.ignore;
        ".psqlrc".source = ../../../../config/.psqlrc;
      };

      xdg.configFile."fd/ignore".text = builtins.readFile ../../../../config/.ignore;
    };
}
  ;
in {
  flake = {
    modules = {
      generic.misc = module.generic;
      homeManager.misc = module.homeManager;
    };
  };
}
