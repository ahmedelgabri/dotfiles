{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.youtube-dl;

in {
  options = with lib; {
    my.youtube-dl = {
      enable = mkEnableOption ''
        Whether to enable youtube-dl module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      users.users.${username} = { packages = with pkgs; [ youtube-dl ]; };

      home-manager = {
        users.${username} = {
          home = {
            file = {
              ".config/youtube-dl" = {
                recursive = true;
                source = ../../config/youtube-dl;
              };
            };
          };
        };
      };
    };
}
