{inputs, ...}: let
  zkModule = {
    pkgs,
    lib,
    config,
    ...
  }: {
    config = {
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
