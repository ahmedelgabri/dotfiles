{inputs, ...}: let
  sshModule = {
    pkgs,
    lib,
    config,
    ...
  }: let
    cfg = config.my.modules.ssh;
  in {
    options = with lib; {
      my.modules.ssh = {
        enable = mkEnableOption ''
          Whether to enable ssh module
        '';
      };
    };

    config = with lib;
      mkIf cfg.enable {
        my.hm.file = {
          ".ssh/config" = {source = ../../config/.ssh/config;};
        };
      };
  };
in {
  flake.modules.darwin.ssh = sshModule;
  flake.modules.nixos.ssh = sshModule;
}
