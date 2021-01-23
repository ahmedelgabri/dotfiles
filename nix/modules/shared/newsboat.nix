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
      users.users.${username} = { packages = with pkgs; [ newsboat w3m ]; };

      home-manager = {
        users.${username} = {
          home = {
            file = {
              ".config/newsboat" = {
                recursive = true;
                source = ../../../config/newsboat;
              };
            };
          };
        };
      };
    };
}
