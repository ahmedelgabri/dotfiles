{inputs, ...}: let
  agenixModule = {
    pkgs,
    lib,
    config,
    ...
  }: {
    config = {
      environment = {
        shellAliases = {
          agenix = "agenix -i ~/.ssh/agenix";
        };
      };
    };
  };
in {
  flake.modules.darwin.agenix = agenixModule;
  flake.modules.nixos.agenix = agenixModule;
}
