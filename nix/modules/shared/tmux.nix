{
  pkgs,
  lib,
  config,
  ...
}: let
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
      my.user = {
        packages = with pkgs; [
          tmux
          next-prayer
          nur.repos.Freed-Wu.tmux-language-server
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
