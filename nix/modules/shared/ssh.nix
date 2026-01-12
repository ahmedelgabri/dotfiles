{...}: {
  flake.sharedModules.ssh = {
    pkgs,
    lib,
    config,
    ...
  }: {
    my.hm.file = {
      ".ssh/config" = {source = ../../../config/.ssh/config;};
    };
  };
}
