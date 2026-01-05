{inputs, ...}: let
  miscModule = {
    pkgs,
    lib,
    config,
    ...
  }: {
    config = {
        my.hm.file = {
          ".gemrc" = {source = ../../config/.gemrc;};
          ".curlrc" = {source = ../../config/.curlrc;};
          ".ignore" = {source = ../../config/.ignore;};
          ".config/fd/ignore" = {
            recursive = true;
            text = builtins.readFile ../../config/.ignore;
          };
          ".psqlrc" = {source = ../../config/.psqlrc;};
        };
    };
  };
in {
  flake.modules.darwin.misc = miscModule;
  flake.modules.nixos.misc = miscModule;
}
