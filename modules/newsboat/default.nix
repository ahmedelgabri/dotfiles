{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.newsboat;

in {
  options = with lib; {
    my.newsboat = {
      enable = mkEnableOption ''
        Whether to enable newsboat module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      users.users.${username} = { packages = with pkgs; [ newsboat mpv w3m ]; };

      home-manager = {
        users.${username} = {
          home = {
            file = {
              ".config/newsboat/config" = { source = ./config; };
              ".config/newsboat/urls" = { source = ./urls; };
              ".config/newsboat/bookmark.sh" = {
                executable = true;
                source = ./bookmark.sh;
              };
              ".config/newsboat/play_podcast.sh" = {
                executable = true;
                source = ./play_podcast.sh;
              };
            };
          };
        };
      };
    };
}
