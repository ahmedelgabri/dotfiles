let
  module =
{
  generic = {
    pkgs,
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
      home.file.".ssh/config" = {
        source = ../../../../config/.ssh/config;
      };
    };
}
  ;
in {
  flake = {
    modules = {
      generic.ssh = module.generic;
      homeManager.ssh = module.homeManager;
    };
  };
}
