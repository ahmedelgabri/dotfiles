{ pkgs, lib, config, ... }:

let

  cfg = config.my.modules.ripgrep;
  xdg = config.home-manager.users.${config.my.username}.xdg;

in {
  options = with lib; {
    my.modules.ripgrep = {
      enable = mkEnableOption ''
        Whether to enable ripgrep module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      environment.variables = {
        RIPGREP_CONFIG_PATH = "${xdg.configHome}/ripgrep/config";
      };

      my.user = { packages = with pkgs; [ ripgrep ]; };

      home-manager = {
        users.${config.my.username} = {
          home = {
            file = {
              ".config/ripgrep" = {
                recursive = true;
                source = ../../../config/ripgrep;
              };
            };
          };
        };
      };
    };
}
