{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.tuir;

in {
  options = with lib; {
    my.tuir = {
      enable = mkEnableOption ''
        Whether to enable tuir module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      users.users.${username} = { packages = with pkgs; [ tuir ]; };

      home-manager = {
        users.${username} = {
          home = {
            file = {
              ".config/tuir/themes" = {
                recursive = true;
                source = ./themes;
              };
              ".config/tuir/tuir.cfg" = { source = ./tuir.cfg; };
            };
          };
        };
      };
    };
}
