{
  pkgs,
  lib,
  config,
  options,
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
      my.env = {
        # I set this in zshenv, because of the loading order. Until I figure this out
        # ZK_NOTEBOOK_DIR = "$NOTES_DIR";
      };

      my.hm.file = {
        ".config/zk" = {
          recursive = true;
          source = ../../../config/zk;
        };
      };
    };
}
