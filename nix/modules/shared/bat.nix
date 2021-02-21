{ pkgs, lib, config, ... }:

with config.my;

let

  cfg = config.my.modules.bat;
  xdg = config.home-manager.users.${username}.xdg;

in {
  options = with lib; {
    my.modules.bat = {
      enable = mkEnableOption ''
        Whether to enable bat module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      environment.variables = {
        BAT_CONFIG_PATH = "${xdg.configHome}/bat/config";
      };

      users.users.${username} = { packages = with pkgs; [ bat ]; };

      home-manager = {
        users.${username} = {
          home = {
            file = {
              ".config/bat" = {
                recursive = true;
                source = ../../../config/bat;
              };
            };
          };
        };
      };
    };
}
