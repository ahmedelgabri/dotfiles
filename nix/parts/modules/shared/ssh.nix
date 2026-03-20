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
