{
  darwin = {
    pkgs,
    lib,
    config,
    ...
  }: {
    config = with lib; {
      homebrew.casks = ["iina"];
      my.user.packages = with pkgs; [mpv];
    };
  };

  nixos = {
    pkgs,
    lib,
    config,
    ...
  }: {
    config = with lib; {
      my.user.packages = with pkgs; [mpv];
    };
  };

  homeManager = {
    lib,
    myConfig,
    ...
  }:
    with lib; {
      xdg.configFile."mpv" = {
        recursive = true;
        source = ../../../../config/mpv;
      };
    };
}
