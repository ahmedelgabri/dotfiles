{inputs, ...}: let
  sshModule = {
    pkgs,
    lib,
    config,
    ...
  }: {
    config = {
      my.hm.file = {
        ".ssh/config" = {source = ../../config/.ssh/config;};
      };
    };
  };
in {
  flake.modules.darwin.ssh = sshModule;
  flake.modules.nixos.ssh = sshModule;
}
