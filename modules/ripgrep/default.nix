{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.ripgrep;
  xdg = config.home-manager.users.${username}.xdg;

in {
  options = with lib; {
    my.ripgrep = {
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

      users.users.${username} = { packages = with pkgs; [ ripgrep ]; };

      home-manager = {
        users.${username} = {
          home = {
            file = {
              ".config/ripgrep" = {
                recursive = true;
                source = ../../config/ripgrep;
              };
            };
          };
        };
      };
    };
}
