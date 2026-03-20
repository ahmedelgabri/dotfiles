{
  darwin = {
    lib,
    config,
    ...
  }: {
    config = with lib; {
      homebrew.casks = ["ghostty@tip"];
    };
  };

  nixos = {
    pkgs,
    lib,
    config,
    ...
  }: {
    config = with lib; {
      my.user.packages = with pkgs; [ghostty];
    };
  };

  homeManager = {
    lib,
    myConfig,
    ...
  }:
    with lib; {
      xdg.configFile."ghostty" = {
        recursive = true;
        source = ../../../../config/ghostty;
      };
    };
}
