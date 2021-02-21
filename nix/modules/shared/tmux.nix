{ pkgs, lib, config, ... }:

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
      my.user = { packages = with pkgs; [ tmux tmuxPlugins.urlview ]; };

      my.hm.file = {
        ".config/tmux" = {
          recursive = true;
          source = ../../../config/tmux;
        };
      };
    };
}
