{
  lib,
  flake-parts-lib,
  ...
}: {
  options = {
    flake = flake-parts-lib.mkSubmoduleOptions {
      modules = lib.mkOption {
        type = lib.types.lazyAttrsOf (lib.types.lazyAttrsOf lib.types.raw);
        default = {};
      };
    };
  };
}
