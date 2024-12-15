{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.my.modules.zk;
in {
  options = with lib; {
    my.modules.zk = {
      enable = mkEnableOption ''
        Whether to enable zk module
      '';
    };
  };

  config = with lib;
    mkIf cfg.enable {
      my.user = {packages = with pkgs; [zk];};

      my.hm.file = {
        ".config/zk" = {
          source = ../../../config/zk;
        };
      };
    };
}
