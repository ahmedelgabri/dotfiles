let
  module = {
    homeManager = _: {
      home.file = {
        ".gemrc".source = ../../../../config/.gemrc;
        ".curlrc".source = ../../../../config/.curlrc;
        ".ignore".source = ../../../../config/.ignore;
        ".psqlrc".source = ../../../../config/.psqlrc;
      };

      xdg.configFile."fd/ignore".text = builtins.readFile ../../../../config/.ignore;
    };
  };
in {
  flake = {
    modules = {
      homeManager.misc = module.homeManager;
    };
  };
}
