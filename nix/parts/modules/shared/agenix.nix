let
  module = {
    pkgs,
    lib,
    config,
    ...
  }: {
    config = with lib; {
      environment = {
        shellAliases = {
          agenix = "agenix -i ~/.ssh/agenix";
        };
      };
    };
  };
in {
  flake.modules.generic.agenix = module;
}
