{ pkgs, lib, config, ... }:

with config.my;

let

  cfg = config.my.modules.lf;

in {
  options = with lib; {
    my.modules.lf = {
      enable = mkEnableOption ''
        Whether to enable lf module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      users.users.${username} = { packages = with pkgs; [ lf chafa fzf ]; };

      home-manager = {
        users.${username} = {
          home = {
            file = {
              ".config/lf" = {
                recursive = true;
                source = ../../../config/lf;
              };
            };
          };
        };
      };
    };
}
