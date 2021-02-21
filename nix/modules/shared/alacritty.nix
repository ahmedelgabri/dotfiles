{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.modules.alacritty;

in {
  options = with lib; {
    my.modules.alacritty = {
      enable = mkEnableOption ''
        Whether to enable alacritty module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      users.users.${username} = { packages = with pkgs; [ alacritty ]; };

      home-manager = {
        users.${username} = {
          home = {
            file = {
              ".config/alacritty" = {
                recursive = true;
                source = ../../../config/alacritty;
              };
            };
          };
        };
      };
    };
}
