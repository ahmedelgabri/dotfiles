let
  module = {
    homeManager = _: {
      home.file.".ssh/config" = {
        source = ../../../../config/.ssh/config;
      };
    };
  };
in {
  flake = {
    modules = {
      homeManager.ssh = module.homeManager;
    };
  };
}
