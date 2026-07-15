let
  module = {
    generic =
      {
        pkgs,
        lib,
        ...
      }:
      {
        config = with lib; {
          my.user.packages = with pkgs; [
            (yt-dlp.override { withAlias = true; })
          ];
        };
      };

    homeManager =
      { config, ... }:
      {
        xdg.configFile = config.lib.file.mkOutOfStoreTree {
          source = ../../../../config/yt-dlp;
          sourceRoot = "${config.home.homeDirectory}/.dotfiles/config/yt-dlp";
          targetRoot = "yt-dlp";
        };
      };
  };
in
{
  flake = {
    modules = {
      generic."yt-dlp" = module.generic;
      homeManager."yt-dlp" = module.homeManager;
    };
  };
}
