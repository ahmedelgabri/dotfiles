{ pkgs, lib, config, ... }:

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
      my.user = { packages = with pkgs; [ alacritty ]; };

      home-manager = {
        users.${config.my.username} = {
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
