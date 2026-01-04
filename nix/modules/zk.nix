{inputs, ...}: let
  zkModule = {
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
          ".config/zk/config.toml" = {
            source = ../../config/zk/config.toml;
          };
          ".config/zk/templates" = {
            recursive = true;
            source = ../../config/zk/templates;
          };
        };
      };
  };
in {
  flake.modules.darwin.zk = zkModule;
  flake.modules.nixos.zk = zkModule;
}
