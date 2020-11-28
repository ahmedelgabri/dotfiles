{ pkgs, lib, config, ... }:

with config.settings;

let

  cfg = config.my.tmux;

in {
  options = with lib; {
    my.tmux = {
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
              ".config/tmux/scripts" = {
                recursive = true;
                source = ./scripts;
              };
              ".config/tmux/tmux.conf" = { source = ./tmux.conf; };
            };
          };
        };
      };
    };
}
