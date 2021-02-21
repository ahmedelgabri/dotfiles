{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.modules.tmux;

in {
  options = with lib; {
    my.modules.tmux = {
      enable = mkEnableOption ''
        Whether to enable tmux module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      users.users.${username} = {
        packages = with pkgs; [ tmux tmuxPlugins.urlview ];
      };

      home-manager = {
        users.${username} = {
          home = {
            file = {
              ".config/tmux" = {
                recursive = true;
                source = ../../../config/tmux;
              };
            };
          };
        };
      };
    };
}
