{ pkgs, lib, config, ... }:

let

  cfg = config.my.modules.tmux;

in
{
  options = with lib; {
    my.modules.tmux = {
      enable = mkEnableOption ''
        Whether to enable tmux module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      environment.shellAliases = {
        # https://github.com/direnv/direnv/wiki/Tmux
        tmux = "${pkgs.direnv}/bin/direnv exec / ${pkgs.tmux}/bin/tmux";
      };

      my.user = {
        packages = with pkgs; [
          tmux
          next-prayer
        ];
      };

      my.hm.file = {
        ".config/tmux" = {
          recursive = true;
          source = ../../../config/tmux;
        };
      };
    };
}
