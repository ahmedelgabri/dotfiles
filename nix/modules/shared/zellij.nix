{ pkgs, lib, config, ... }:

let

  cfg = config.my.modules.zellij;

in
{
  options = with lib; {
    my.modules.zellij = {
      enable = mkEnableOption ''
        Whether to enable zellij module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      my.user = {
        packages = with pkgs; [
          zellij
        ];
      };

      my.hm.file = {
        ".config/zellij" = {
          recursive = true;
          source = ../../../config/zellij;
        };
      };
    };
}
